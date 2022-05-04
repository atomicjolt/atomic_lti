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
        @app.call(env)
      end
    end

    protected

    def build_oidc_response(request, state, nonce, redirect_uri)
      platform = AtomicLti::Platform.find_by(iss: request.params["iss"])
      if !platform
        raise LtiAdvantage::Exceptions::NoLTIPlatform, "No LTI Platform found for iss #{request.params["iss"]}"
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
