module AtomicLti
  module Services
    class Base

      def initialize(iss:, deployment_id:)
        @iss = iss
        @deployment_id = deployment_id
      end

      def headers(options = {})
        @token ||= AtomicLti::Authorization.request_token(iss: @iss, deployment_id: @deployment_id)
        {
          "Authorization" => "Bearer #{@token['access_token']}",
        }.merge(options)
      end

      def get_next_url(response)
        link = response.headers["link"]
        return nil if link.blank?

        if url = link.split(",").detect { |l| l.split(";")[1].strip == 'rel="next"' }
          url.split(";")[0].gsub(/[\<\>\s]/, "")
        end
      end

    end
  end
end
