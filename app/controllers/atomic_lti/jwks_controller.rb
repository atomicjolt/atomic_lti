module AtomicLti
  class JwksController < ::ApplicationController
    def index
      respond_to do |format|
        # Map is required or the outer to_json will show your private keys to the world
        format.json { render json: { keys: jwks_from_domain.map(&:to_json) }.to_json }
      end
    end

    protected

    def jwks_from_domain
      Jwk.where(domain: request.host_with_port).presence || Jwk.where(domain: nil)
    end
  end
end
