module AtomicLti
  module Services
    class Base

      def initialize(id_token_decoded: nil, iss: nil, deployment_id: nil)
        token_iss = nil
        token_deployment_id = nil

        if id_token_decoded.present?
          token_iss = id_token_decoded["iss"]
          token_deployment_id = id_token_decoded[AtomicLti::Definitions::DEPLOYMENT_ID]
        end

        @id_token_decoded = id_token_decoded
        @iss = iss || token_iss
        @deployment_id = deployment_id || token_deployment_id
      end

      def scopes; end

      def headers(options = {})
        @token ||= AtomicLti::Authorization.request_token(iss: @iss, deployment_id: @deployment_id, scopes: scopes)
        {
          "Authorization" => "Bearer #{@token['access_token']}",
        }.merge(options)
      end

      def get_next_url(response)
        next_url, = AtomicLti::PagingHelper.response_link_urls(response, "next")
        next_url
      end

    end
  end
end
