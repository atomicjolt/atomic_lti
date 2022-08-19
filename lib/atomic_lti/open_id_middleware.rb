module AtomicLti
  class OpenIdMiddleware
    def initialize(app)
      @app = app
    end

    def init_paths
      [
        AtomicLti.oidc_init_path || "/lti_launches/init"
      ]
    end

    def redirect_paths
      [
        AtomicLti::Engine.routes.url_for(only_path: true, controller: 'atomic_lti/launches', action: 'redirect'),
      ]
    end

    def handle_init(request)
      nonce = SecureRandom.hex(64)

      redirect_uri = request.params["target_link_uri"] 

      state = AtomicLti::OpenId.state
      url = build_oidc_response(request, state, nonce, redirect_uri)

      headers = { "Location" => url, "Content-Type" => "text/html" }
      Rack::Utils.set_cookie_header!(headers, "open_id_state", state)
      [302, headers, ["Found"]]
    end

    # def handle_redirect(request)
    #   lti_token = AtomicLti::Authorization.validate_token(
    #     request.params["id_token"],
    #   )
    #   return not_found("Invalid launch") if lti_token.blank?

    #   target_link_uri = lti_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]
    #   redirect_params = {
    #     state: request.params["state"],
    #     id_token: request.params["id_token"],
    #   }
    #   html = ApplicationController.renderer.render(
    #     :html,
    #     layout: false,
    #     template: "atomic_lti/shared/redirect",
    #     assigns: { launch_params: redirect_params, launch_url: target_link_uri },
    #   )

    #   [200, { "Content-Type" => "text/html" }, [html]]
    # end

    def call(env)
      begin
        request = Rack::Request.new(env)

        case request.path
        when *init_paths
          handle_init(request)
        when *redirect_paths
          # handle_redirect(request)
        else
          if request.params["id_token"].present? && request.params["state"].present?
            id_token = request.params["id_token"]
            state = request.params["state"]
            url = request.url

            payload = valid_token(state: state, id_token: id_token, url: url)
            if payload
              decoded_jwt = JWT.decode(id_token, nil, false)[0]

              update_deployment(id_token: decoded_jwt)
              update_platform_instance(id_token: decoded_jwt)

              errors = decoded_jwt.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'errors')
              if errors.present?
                Rails.logger.error("Detected errors in lti launch: #{errors}, id_token: #{id_token}")
              end

              env['atomic.validated.decoded_id_token'] = decoded_jwt
              env['atomic.validated.id_token'] = id_token
            end
          end
          @app.call(env)
        end
      rescue StandardError => e
          Rails.logger.error("Error in OpenIdMiddleware: #{e}")
          raise e if Rails.env == "development"
          @app.call(env)
      end
    end

    protected

    def update_platform_instance(id_token:)
      if id_token[AtomicLti::Definitions::TOOL_PLATFORM_CLAIM].present? && id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'guid').present?
        name = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'name')
        version = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'version')
        product_family_code = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'product_family_code')

        AtomicLti::PlatformInstance.create_with(
          name: name,
          version: version,
          product_family_code: product_family_code,
        ).find_or_create_by!(
          iss: id_token['iss'],
          guid: id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, 'guid')
        ).update!(
          name: name,
          version: version,
          product_family_code: product_family_code,
        )
      else
        Rails.logger.info("No platform guid recieved: #{id_token}")
      end
    end

    def update_lti_context(id_token:)
    end

    def update_deployment(id_token:)
      client_id = id_token["aud"]
      iss = id_token["iss"]
      deployment_id = id_token[AtomicLti::Definitions::DEPLOYMENT_ID]
      platform_guid = id_token.dig(AtomicLti::Definitions::TOOL_PLATFORM_CLAIM, "guid")

      Rails.logger.debug("Associating deployment: #{iss}/#{deployment_id} with client_id: iss: #{iss} / client_id: #{client_id} / platform_guid: #{platform_guid}")


      AtomicLti::Deployment
        .create_with(
          client_id: client_id,
          platform_guid: platform_guid
        ).find_or_create_by!(
          iss: iss,
          deployment_id: deployment_id
        ).update!(
          client_id: client_id,
          platform_guid: platform_guid
        )
    end

    # TODO check this is legit
    def valid_token(state:, id_token:, url:)

          # Validate the s tate by checking the database for the nonce
          valid_state = AtomicLti::OpenId.validate_open_id_state(state)

          return false if !valid_state

          token = begin
            AtomicLti::Authorization.validate_token(id_token)
          rescue JWT::DecodeError => e
            Rails.logger.error("Unable to decode jwt: #{e}", e)
          end

          return nil if token.nil?
 
          # Validate that we are at the target_link_uri
          target_link_uri = token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]
          if target_link_uri != url
            return nil
          end

          token
    end

    def build_oidc_response(request, state, nonce, redirect_uri)
      platform = AtomicLti::Platform.find_by(iss: request.params["iss"])
      if !platform
        raise AtomicLti::Exceptions::NoLTIPlatform, "No LTI Platform found for iss #{request.params["iss"]}"
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
  end
end
