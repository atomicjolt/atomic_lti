module AtomicLti
  module Services
    class Base

      def initialize(current_jwk, iss, token_url, lti_token)
        @current_jwk = current_jwk
        @iss = iss
        @token_url = token_url
        @lti_token = lti_token
      end

      def headers(options = {})
        @token ||= AtomicLti::Authorization.request_token(@current_jwk, @iss, @token_url, @lti_token)
        {
          "Authorization" => "Bearer #{@token['access_token']}",
        }.merge(options)
      end

    end
  end
end
