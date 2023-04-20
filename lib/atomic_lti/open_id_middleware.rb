module AtomicLti
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

      nonce, state, csrf_token = AtomicLti::OpenId.generate_state

      headers = { "Content-Type" => "text/html" }
      Rack::Utils.set_cookie_header!(
        headers, "open_id_cookie_storage",
        { value: "1", path: "/", max_age: 365.days, http_only: false, secure: true, same_site: "None" }
      )
      Rack::Utils.set_cookie_header!(
        headers, "open_id_#{state}",
        { value: csrf_token, path: "/", max_age: 5.minutes, http_only: false, secure: true, same_site: "None" }
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
            relaunch_init_url: relaunch_init_url(request),
            privacy_policy_html: AtomicLti.privacy_policy_html,
            settings: {
              state: state,
              csrf_token: csrf_token,
              response_url: response_url,
              lti_storage_params: lti_storage_params,
            },
          },
        )

        [200, headers, [html]]
      end
    end

    def handle_redirect(request)
      raise AtomicLti::Exceptions::NoLTIToken if request.params["id_token"].blank?

      lti_token = AtomicLti::Authorization.validate_token(
        request.params["id_token"],
      )

      AtomicLti::Lti.validate!(lti_token)
      platform = AtomicLti::Platform.find_by!(iss: lti_token["iss"])

      uri = URI(request.url)
      # Technically the target_link_uri is not required and the certification suite
      # does not send it on a deep link launch. Typically target link uri will be present
      # but at least for the certification suite we have to have a backup default
      # value that can be set in the configuration of Atomic LTI using
      # the default_deep_link_path
      target_link_uri = lti_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM] ||
        File.join("#{uri.scheme}://#{uri.host}", AtomicLti.default_deep_link_path)

      redirect_params = {
        state: request.params["state"],
        id_token: request.params["id_token"],
        csrf_token: "",
      }
      if request.params["lti_storage_target"].present? && AtomicLti.use_post_message_storage
        lti_storage_params = build_lti_storage_params(request, platform)
      end
      html = ApplicationController.renderer.render(
        :html,
        layout: false,
        template: "atomic_lti/shared/redirect",
        assigns: {
          launch_params: redirect_params,
          launch_url: target_link_uri,
          settings: {
            require_csrf: AtomicLti.enforce_csrf_protection,
            state: request.params["state"],
            lti_storage_params: lti_storage_params,
          },
        },
      )

      [200, { "Content-Type" => "text/html" }, [html]]

    rescue JWT::ExpiredSignature
      render_error(401, "The launch has expired. Please launch the application again.")
    rescue JWT::DecodeError
      render_error(401, "The launch token is invalid.")
    rescue AtomicLti::Exceptions::NoLTIToken
      render_error(401, "Invalid launch. Please launch the application again.")
    end

    def matches_redirect?(request)
      raise AtomicLti::Exceptions::ConfigurationError.new("AtomicLti.oidc_redirect_path is not configured") if AtomicLti.oidc_redirect_path.blank?

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
      id_token = request.params["id_token"]
      url = request.url

      payload = valid_token(id_token: id_token, url: url)
      if !payload
        Rails.logger.info("Invalid lti launch: id_token: #{payload} - id_token: #{id_token} - url: #{url}")
        return render_error(401, "Invalid LTI launch. Please launch the application again.")
      end

      # Validate the state and csrf token
      state = request.params["state"]
      csrf_token = request.cookies["open_id_#{state}"] || request.params["csrf_token"]
      if csrf_token.blank? && AtomicLti.enforce_csrf_protection
        return render_error(401, "Unauthorized. Please check that your browser allows cookies.")
      end

      if !AtomicLti::OpenId.validate_state(payload["nonce"], state, csrf_token)
        return render_error(401, "Invalid launch state")
      end

      decoded_jwt = payload

      update_install(id_token: decoded_jwt)
      update_platform_instance(id_token: decoded_jwt)
      update_deployment(id_token: decoded_jwt)
      update_lti_context(id_token: decoded_jwt)

      errors = decoded_jwt.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "errors")
      if errors.present? && !errors["errors"].empty?
        Rails.logger.error("Detected errors in lti launch: #{errors}, id_token: #{id_token}")
      end

      env["atomic.validated.decoded_id_token"] = decoded_jwt
      env["atomic.validated.id_token"] = id_token

      @app.call(env)

    rescue JWT::ExpiredSignature
      render_error(401, "The launch has expired. Please launch the application again.")
    rescue JWT::DecodeError
      render_error(401, "The launch token is invalid.")
    end

    def error!(body = "Error", status = 500, headers = {"Content-Type" => "text/html"})
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

    def valid_token(id_token:, url:)
      token = false

      begin
        token = AtomicLti::Authorization.validate_token(id_token)
      rescue JWT::DecodeError => e
        Rails.logger.error("Unable to decode jwt: #{e}, #{e.backtrace}")
        return false
      end

      return false if token.nil?

      AtomicLti::Lti.validate!(token, url, true)

      token
    end

    def relaunch_init_url(request)
      uri = URI.parse(request.url)
      uri.fragment = uri.query = nil
      params = request.params
      params.delete("lti_storage_target");
      [uri.to_s, "?", params.to_query].join
    end

    def build_oidc_response(request, state, nonce, redirect_uri)
      platform = AtomicLti::Platform.find_by(iss: request.params["iss"])
      if !platform
        raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: request.params["iss"])
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
        origin_support_broken: !AtomicLti.set_post_message_origin,
        oidc_url: platform.oidc_url,
      }
    end
  end
end
