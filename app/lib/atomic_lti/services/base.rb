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

      def service_get(*args)
        logged_service_call(:get, *args)
      end

      def service_put(*args)
        logged_service_call(:put, *args)
      end

      def service_post(*args)
        logged_service_call(:post, *args)
      end

      def service_delete(*args)
        logged_service_call(:delete, *args)
      end

      def logged_service_call(method, *args)
        begin
          Rails.logger.debug("Making service call #{method} #{args}")
          response = HTTParty.send(method, *args)

          if response.body.present? && response.success?
            parsed_body = JSON.parse(response.body)
          end

          if !response.success? && response.code != 404
            Rails.logger.error("Encountered an error while making service request #{method} #{args}")
            Rails.logger.error("Got code #{response.code}")
            Rails.logger.error(response.body)
          end

          [response, parsed_body]
        rescue JSON::ParserError => e
          # We do not reraise this error as previously we did not check at all for valid json. This is purely for
          # logging purposes.
          Rails.logger.error("Encountered an error while parsing response for service request #{method} #{args}")
          Rails.logger.error(response.body)
          Rails.logger.error(e)

          [response, nil]
        rescue StandardError => e
          Rails.logger.error("Encountered an error while making service request #{method} #{args}")
          Rails.logger.error(response&.body)
          Rails.logger.error(e)

          raise e
        end
      end
    end
  end
end
