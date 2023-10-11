module AtomicLti
  # This is the same prefix used in the npm package. There's not a great way to share constants between ruby and npm.
  # Don't change it unless you change it in the Javascript as well.
  OPEN_ID_COOKIE_PREFIX = "open_id_".freeze

  class OpenIdMiddleware
    def initialize(app)
      @app = app
    end

    def init_paths
      [
        AtomicLti.oidc_init_path,
      ]
    end

    def redirect_paths
      [
        AtomicLti.oidc_redirect_path,
      ]
    end

    def handle_init(request)
      platform = AtomicLti::Platform.find_by(iss: request.params["iss"])
      if !platform
        raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: request.params["iss"])
      end

      nonce, state = AtomicLti::OpenId.generate_state

      headers = { "Content-Type" => "text/html" }
      Rack::Utils.set_cookie_header!(
        headers, "#{OPEN_ID_COOKIE_PREFIX}storage",
        { value: "1", path: "/", max_age: 365.days, http_only: false, secure: true, same_site: "None" }
      )
      Rack::Utils.set_cookie_header!(
        headers, "#{OPEN_ID_COOKIE_PREFIX}#{state}",
        { value: 1, path: "/", max_age: 1.minute, http_only: false, secure: true, same_site: "None" }
      )

      redirect_uri = [request.base_url, AtomicLti.oidc_redirect_path].join
      response_url = build_oidc_response(request, state, nonce, redirect_uri)

      if request.cookies.present? || !AtomicLti.enforce_csrf_protection
        # we know cookies will work, so redirect
        headers["Location"] = response_url

        [302, headers, ["Found"]]
      else
        # cookies might not work, so render our javascript form
        if request.params["lti_storage_target"].present? && AtomicLti.use_post_message_storage
          lti_storage_params = build_lti_storage_params(request, platform)
        end

        html = ApplicationController.renderer.render(
          :html,
          layout: false,
          template: "atomic_lti/shared/init",
          assigns: {
            settings: {
              state: state,
              responseUrl: response_url,
              ltiStorageParams: lti_storage_params,
              relaunchInitUrl: relaunch_init_url(request),
              privacyPolicyUrl: AtomicLti.privacy_policy_url,
              privacyPolicyMessage: AtomicLti.privacy_policy_message,
              openIdCookiePrefix: OPEN_ID_COOKIE_PREFIX,
            },
          },
        )

        [200, headers, [html]]
      end
    end

    def validate_launch(request, validate_target_link_url, destroy_state)
      # Validate and decode id_token
      raise AtomicLti::Exceptions::NoLTIToken if request.params["id_token"].blank?

      id_token_decoded = AtomicLti::Authorization.validate_token(request.params["id_token"])

      raise AtomicLti::Exceptions::InvalidLTIToken.new if id_token_decoded.nil?

      # Validate id token contents
      AtomicLti::Lti.validate!(id_token_decoded, request.url, validate_target_link_url)

      # Check for the state cookie
      state_verified = false
      state = request.params["state"]
      if request.cookies["open_id_#{state}"]
        state_verified = true
      end

      # Validate the state and nonce
      if !AtomicLti::OpenId.validate_state(id_token_decoded["nonce"], state, destroy_state)
        raise AtomicLti::Exceptions::OpenIDStateError.new("Invalid OIDC state.")
      end

      [id_token_decoded, state, state_verified]
    end

    def handle_redirect(request)
      id_token_decoded, _state, _state_verified = validate_launch(request, false, false)

      uri = URI(request.url)
      # Technically the target_link_uri is not required and the certification suite
      # does not send it on a deep link launch. Typically target link uri will be present
      # but at least for the certification suite we have to have a backup default
      # value that can be set in the configuration of Atomic LTI using
      # the default_deep_link_path
      target_link_uri = id_token_decoded[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM] ||
        File.join("#{uri.scheme}://#{uri.host}", AtomicLti.default_deep_link_path)

      html = ApplicationController.renderer.render(
        :html,
        layout: false,
        template: "atomic_lti/shared/redirect",
        assigns: {
          launch_params: request.params,
          launch_url: target_link_uri,
        },
      )

      [200, { "Content-Type" => "text/html" }, [html]]
    end

    def matches_redirect?(request)
      if AtomicLti.oidc_redirect_path.blank?
        raise AtomicLti::Exceptions::ConfigurationError.new("AtomicLti.oidc_redirect_path is not configured")
      end

      redirect_uri = URI.parse(AtomicLti.oidc_redirect_path)
      redirect_path_params = if redirect_uri.query
                               CGI.parse(redirect_uri.query)
                             else
                               []
                             end

      matches_redirect_path = request.path == redirect_uri.path

      return false if !matches_redirect_path

      params_match = redirect_path_params.all? { |key, values| request.params[key] == values.first }

      matches_redirect_path && params_match
    end

    def matches_target_link?(request)
      AtomicLti.target_link_path_prefixes.any? do |prefix|
        request.path.starts_with? prefix
      end || request.path.starts_with?(AtomicLti.default_deep_link_path)
    end

    def handle_lti_launch(env, request)
      id_token_decoded, state, state_verified = validate_launch(request, true, true)

      id_token = request.params["id_token"]
      update_install(id_token: id_token_decoded)
      update_platform_instance(id_token: id_token_decoded)
      update_deployment(id_token: id_token_decoded)
      update_lti_context(id_token: id_token_decoded)

      errors = id_token_decoded.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "errors")
      if errors.present? && !errors["errors"].empty?
        Rails.logger.error("Detected errors in lti launch: #{errors}, id_token: #{id_token}")
      end

      env["atomic.validated.decoded_id_token"] = id_token_decoded
      env["atomic.validated.id_token"] = id_token

      platform = AtomicLti::Platform.find_by!(iss: id_token_decoded["iss"])

      # Add the values needed to do client side validate to the environment
      env["atomic.validated.state_validation"] = {
        state: state,
        state_verified: state_verified,
      }

      if !state_validated && request.params["lti_storage_target"].present? && AtomicLti.use_post_message_storage
        env["atomic.validated.state_validation"][:lti_storage_params] =
          build_lti_storage_params(request, platform)
      end

      @app.call(env)

      # Delete the state cookie
      status, headers, body = @app.call(env)
      # Rack::Utils.delete_cookie_header(headers, "#{OPEN_ID_COOKIE_PREFIX}#{state}")
      [status, headers, body]
    end

    def error!(body = "Error", status = 500, headers = { "Content-Type" => "text/html" })
      [status, headers, [body]]
    end

    def call(env)
      request = Rack::Request.new(env)
      if init_paths.include?(request.path)
        handle_init(request)
      elsif matches_redirect?(request)
        handle_redirect(request)
      elsif matches_target_link?(request) && request.params["id_token"].present?
        handle_lti_launch(env, request)
      else
        @app.call(env)
      end
    end

    protected

    def render_error(status, message)
      html = ApplicationController.renderer.render(
        :html,
        layout: false,
        template: "atomic_lti/shared/error",
        assigns: {
          message: message || "There was an error during the launch. Please try again.",
        },
      )

      [status || 404, { "Content-Type" => "text/html" }, [html]]
    end

    def update_platform_instance(id_token:)
      if id_token[AtomicLti::Definitions::TOOL_PLATFORM_CLAIM].present? &&
          id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid").present?
        name = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "name")
        version = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "version")
        product_family_code = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "product_family_code")

        AtomicLti::PlatformInstance.create_with(
          name: name,
          version: version,
          product_family_code: product_family_code,
        ).find_or_create_by!(
          iss: id_token["iss"],
          guid: id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid"),
        ).update!(
          name: name,
          version: version,
          product_family_code: product_family_code,
        )
      else
        Rails.logger.info("No platform guid recieved: #{id_token}")
      end
    end

    def update_install(id_token:)
      client_id = AtomicLti::Lti.client_id(id_token)
      iss = id_token["iss"]

      if client_id.present? && iss.present?

        AtomicLti::Install.find_or_create_by!(
          iss: iss,
          client_id: client_id,
        )
      else
        Rails.logger.info("No client_id recieved: #{id_token}")
      end
    end

    def update_lti_context(id_token:)
      if id_token[AtomicLti::Definitions::CONTEXT_CLAIM].present? &&
          id_token[AtomicLti::Definitions::CONTEXT_CLAIM]["id"].present?
        iss = id_token["iss"]
        deployment_id = id_token[AtomicLti::Definitions::DEPLOYMENT_ID]
        context_id = id_token[AtomicLti::Definitions::CONTEXT_CLAIM]["id"]
        label = id_token[AtomicLti::Definitions::CONTEXT_CLAIM]["label"]
        title = id_token[AtomicLti::Definitions::CONTEXT_CLAIM]["title"]
        types = id_token[AtomicLti::Definitions::CONTEXT_CLAIM]["type"]

        AtomicLti::Context.create_with(
          label: label,
          title: title,
          types: types,
        ).find_or_create_by!(
          iss: iss,
          deployment_id: deployment_id,
          context_id: context_id,
        ).update!(
          label: label,
          title: title,
          types: types,
        )
      else
        Rails.logger.info("No context claim recieved: #{id_token}")
      end
    end

    def update_deployment(id_token:)
      client_id = AtomicLti::Lti.client_id(id_token)
      iss = id_token["iss"]
      deployment_id = id_token[AtomicLti::Definitions::DEPLOYMENT_ID]
      platform_guid = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid")

      Rails.logger.debug("Associating deployment: #{iss}/#{deployment_id} with client_id: iss: #{iss} / client_id: #{client_id} / platform_guid: #{platform_guid}")

      AtomicLti::Deployment.
        create_with(
          client_id: client_id,
          platform_guid: platform_guid,
        ).find_or_create_by!(
          iss: iss,
          deployment_id: deployment_id,
        ).update!(
          client_id: client_id,
          platform_guid: platform_guid,
        )
    end

    def relaunch_init_url(request)
      uri = URI.parse(request.url)
      uri.fragment = uri.query = nil
      params = request.params
      params.delete("lti_storage_target")
      [uri.to_s, "?", params.to_query].join
    end

    def build_oidc_response(request, state, nonce, redirect_uri)
      platform = AtomicLti::Platform.find_by(iss: request.params["iss"])
      if !platform
        raise AtomicLti::Exceptions::NoLTIPlatform.new("No platform was found for iss: #{request.params['iss']}")
      end

      uri = URI.parse(platform.oidc_url)
      uri_params = Rack::Utils.parse_query(uri.query)
      auth_params = {
        response_type: "id_token",
        redirect_uri: redirect_uri,
        response_mode: "form_post",
        client_id: request.params["client_id"],
        scope: "openid",
        state: state,
        login_hint: request.params["login_hint"],
        prompt: "none",
        lti_message_hint: request.params["lti_message_hint"],
        nonce: nonce,
      }.merge(uri_params)
      uri.fragment = uri.query = nil

      [uri.to_s, "?", auth_params.to_query].join
    end

    def build_lti_storage_params(request, platform)
      {
        target: request.params["lti_storage_target"],
        originSupportBroken: !AtomicLti.set_post_message_origin,
        platformOIDCUrl: platform.oidc_url,
      }
    end
  end
end
