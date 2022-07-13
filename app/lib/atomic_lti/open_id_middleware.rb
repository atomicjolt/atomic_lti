module AtomicLti
  class OpenIdMiddleware
    def initialize(app)
      @app = app
    end

    OIDC_INIT_PATH = %r{^/lti[/_]launches/init$}.freeze
    OIDC_REDIRECT_PATH = %r{/^lti[/_]launches/redirect$}.freeze

    def init_paths
      [
        AtomicLti::Engine.routes.url_for(only_path: true, controller: 'atomic_lti/launches', action: 'init'),
        "/lti_launches/init",
      ]
    end

    def redirect_paths
      [
        AtomicLti::Engine.routes.url_for(only_path: true, controller: 'atomic_lti/launches', action: 'redirect'),
      ]
    end

    def handle_init(request)
      nonce = SecureRandom.hex(64)
      redirect_uri = AtomicLti::Engine.routes.url_for(
        host: request.host,
        controller: "atomic_lti/launches",
        action: "redirect",
        protocol: "https",
      )
      state = AtomicLti::OpenId.state
      url = build_oidc_response(request, state, nonce, redirect_uri)

      headers = { "Location" => url, "Content-Type" => "text/html" }
      Rack::Utils.set_cookie_header!(headers, "open_id_state", state)
      [302, headers, ["Found"]]
    end

    def handle_redirect(request)
      lti_token = AtomicLti::LtiAdvantage::Authorization.validate_token(
        request.params["id_token"],
      )
      return not_found("Invalid launch") if lti_token.blank?

      target_link_uri = lti_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]
      redirect_params = {
        state: request.params["state"],
        id_token: request.params["id_token"],
      }
      html = ApplicationController.renderer.render(
        :html,
        layout: false,
        template: "atomic_lti/shared/redirect",
        assigns: { launch_params: redirect_params, launch_url: target_link_uri },
      )

      [200, { "Content-Type" => "text/html" }, [html]]
    end

    def call(env)
      request = Rack::Request.new(env)

      case request.path
      when *init_paths
        handle_init(request)
      when *redirect_paths
        handle_redirect(request)
      else

        # TODO wrap in try catch
        if request.params["id_token"].present? && request.params["state"].present?
          id_token = request.params["id_token"]
          state = request.params["state"]
          url = request.url

          payload = valid_token(state: state, id_token: id_token, url: url) 
          if payload
            client_id = payload["aud"]
            iss = payload["iss"]
            deployment_id = payload[LtiAdvantage::Definitions::DEPLOYMENT_ID]

            env['atomic.validated.id_token'] = id_token
            env['atomic.validated.lti_advantage.client_id'] = client_id
            env['atomic.validated.lti_advantage.iss'] = iss
            env['atomic.validated.lti_advantage.deployment_id'] = deployment_id
          end

        end

        @app.call(env)
      end
    end

    protected

    # TODO check this is legit
    def valid_token(state:, id_token:, url:)

          # Validate the state by checking the database for the nonce
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
