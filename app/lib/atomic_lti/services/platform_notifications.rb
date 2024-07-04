module AtomicLti
  module Services
    class PlatformNotifications < AtomicLti::Services::Base
      def initialize(id_token_decoded:)
        super(id_token_decoded: id_token_decoded)
      end

      def scopes
        [AtomicLti::Definitions::PNS_SCOPE_NOTICEHANDLERS]
      end

      def endpoint
        url = @id_token_decoded.dig(AtomicLti::Definitions::PLATFORM_NOTIFICATION_SERVICE_CLAIM, "platform_notification_service_url")
        raise AtomicLti::Exceptions::PlatformNotificationsError, "Unable to access platform notifications" unless url.present?

        url
      end

      def url_for(query = nil)
        url = endpoint.dup
        url << "?#{query}" if query.present?
        url
      end

      def self.enabled?(id_token_decoded)
        return false unless id_token_decoded&.dig(PLATFORM_NOTIFICATION_SERVICE_CLAIM)

        (PLATFORM_NOTIFICATION_SERVICE_VERSIONS &
          (id_token_decoded.dig(PLATFORM_NOTIFICATION_SERVICE_CLAIM, "service_versions") || [])).present?
      end

      def valid?
        self.class.enabled?(@id_token_decoded)
      end

      # List platform notifications
      def list(query: {}, page_url: nil)
        url = if page_url.present?
                page_url
              else
                uri = Addressable::URI.parse(endpoint)
                uri.query_values = (uri.query_values || {}).merge(query)
                uri.to_str
              end
        response, = service_get(
          url,
          headers: headers(),
        )

        response
      end

      def list_all(query: {})
        page_body = nil

        members = AtomicLti::PagingHelper.paginate_request do |next_link|
          result_page = list(query: query, page_url: next_link)
          page_body = JSON.parse(result_page.body)
          [page_body["members"], get_next_url(result_page)]
        end

        page_body["members"] = members
        page_body
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
            "LTI token is missing required field #{AtomicLti::Definitions::DEPLOYMENT_ID}"
          )
        end

        if decoded_token[AtomicLti::Definitions::NOTICE_TYPE_CLAIM].blank?
          errors.push(
            "LTI token is missing required claim #{AtomicLti::Definitions::NOTICE_TYPE}"
          )
        end

        if errors.length > 0
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
