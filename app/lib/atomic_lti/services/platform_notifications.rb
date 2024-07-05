module AtomicLti
  module Services
    class PlatformNotifications < AtomicLti::Services::Base
      def scopes
        [AtomicLti::Definitions::PNS_SCOPE_NOTICEHANDLERS]
      end

      def endpoint
        url = @id_token_decoded.dig(AtomicLti::Definitions::PLATFORM_NOTIFICATION_SERVICE_CLAIM, "platform_notification_service_url")
        raise AtomicLti::Exceptions::PlatformNotificationsError, "Unable to access platform notifications" if url.blank?

        url
      end

      def url_for(query = nil)
        url = endpoint.dup
        url << "?#{query}" if query.present?
        url
      end

      def self.enabled?(id_token_decoded)
        return false unless id_token_decoded&.dig(AtomicLti::Definitions::PLATFORM_NOTIFICATION_SERVICE_CLAIM)

        (AtomicLti::Definitions::PLATFORM_NOTIFICATION_SERVICE_VERSIONS &
          (id_token_decoded.dig(AtomicLti::Definitions::PLATFORM_NOTIFICATION_SERVICE_CLAIM, "service_versions") || [])).present?
      end

      def valid?
        self.class.enabled?(@id_token_decoded)
      end

      # Get platform notifications
      def get(query: {})
        uri = Addressable::URI.parse(endpoint)
        uri.query_values = (uri.query_values || {}).merge(query)
        url = uri.to_str

        response, = service_get(url, headers:)
        response.parsed_response
      end

      def update(notice_type, handler)
        content_type = { "Content-Type" => "application/json" }
        payload = { notice_type:, handler: }
        response, = service_put(endpoint, body: JSON.dump(payload), headers: headers(content_type))
        response
      end

      def self.validate_notification(notification)
        decoded_token = AtomicLti::Authorization.validate_token(notification)
        if decoded_token.blank?
          raise AtomicLti::Exceptions::InvalidPlatformNotification
        end

        errors = []

        if decoded_token["iss"].blank?
          errors.push("LTI token is missing required field iss")
        end

        if decoded_token["aud"].blank?
          errors.push("LTI token is missing required field aud")
        end

        if decoded_token["aud"].is_a?(Array) && decoded_token["aud"].length > 1
          # OpenID Connect spec specifies the AZP should exist and be an AUD
          if decoded_token["azp"].blank?
            errors.push("LTI token has multiple aud and is missing required field azp")
          elsif decoded_token["aud"].exclude?(decoded_token["azp"])
            errors.push("LTI token azp is not one of the aud's")
          end
        end

        if decoded_token[AtomicLti::Definitions::DEPLOYMENT_ID].blank?
          errors.push(
            "LTI token is missing required field #{AtomicLti::Definitions::DEPLOYMENT_ID}",
          )
        end

        if decoded_token[AtomicLti::Definitions::NOTICE_TYPE_CLAIM].blank?
          errors.push(
            "LTI token is missing required claim #{AtomicLti::Definitions::NOTICE_TYPE_CLAIM}",
          )
        end

        if errors.present?
          raise Exceptions::InvalidPlatformNotification.new(errors.join(" "))
        end

        if decoded_token[AtomicLti::Definitions::LTI_VERSION].blank?
          raise AtomicLti::Exceptions::NoLTIVersion
        end

        raise AtomicLti::Exceptions::InvalidLTIVersion unless AtomicLti::Lti.valid_version?(decoded_token)

        decoded_token
      end
    end
  end
end
