# Support Open ID connect flow for LTI 1.3
module AtomicLti
  module OpenIdConnectSupport
    extend ActiveSupport::Concern

    included do
      def self.oidc_actions
        [:init, :redirect]
      end
    end

    def init
      nonce = SecureRandom.hex(64)
      redirect_uri = url_for(action: "redirect")
      state = AtomicLti::OpenId.state
      url = build_oidc_response(state, nonce, redirect_uri)
      cookies[:open_id_state] = state
      respond_to do |format|
        format.html { redirect_to url }
      end
    end

    # Support Open ID connect flow for LTI 1.3
    def redirect
      lti_token = AtomicLti::LtiAdvantage::Authorization.validate_token(
        params[:id_token],
      )
      return not_found("Invalid launch") if lti_token.blank?

      target_link_uri = lti_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]
      redirect_params = {
        state: params["state"],
        id_token: params["id_token"],
      }
      @launch_params = redirect_params
      @launch_url = target_link_uri
      render layout: false, template: "atomic_lti/shared/redirect"
    end

    protected

    def build_oidc_response(state, nonce, redirect_uri)
      platform = AtomicLti::Platform.find_by(iss: params["iss"])
      if !platform
        raise LtiAdvantage::Exceptions::NoLTIPlatform, "No LTI Platform found for iss #{params['iss']}"
      end

      uri = URI.parse(platform.oidc_url)
      uri_params = Rack::Utils.parse_query(uri.query)
      auth_params = {
        response_type: "id_token",
        redirect_uri: redirect_uri,
        response_mode: "form_post",
        client_id: params[:client_id],
        scope: "openid",
        state: state,
        login_hint: params[:login_hint],
        prompt: "none",
        lti_message_hint: params[:lti_message_hint],
        nonce: nonce,
      }.merge(uri_params)
      uri.fragment = uri.query = nil
      [uri.to_s, "?", auth_params.to_query].join
    end
  end
end
