module AtomicLti
  module Services
    class NamesAndRoles < AtomicLti::Services::Base

      def initialize(lti_token:)
        super(lti_token: lti_token)
      end

      def endpoint
        url = @lti_token.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM, "context_memberships_url")
        raise AtomicLti::Exceptions::NamesAndRolesError, "Unable to access names and roles" unless url.present?

        url
      end

      def url_for(query = nil)
        url = endpoint.dup
        url << "?#{query}" if query.present?
        url
      end

      def self.enabled?(lti_token)
        return false unless lti_token&.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM)

        (AtomicLti::Definitions::NAMES_AND_ROLES_SERVICE_VERSIONS &
          (lti_token.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM, "service_versions") || [])).present?
      end

      def valid?
        self.class.enabled?(@lti_token)
      end

      # List names and roles
      # limit query param - see 'Limit query parameter' section of NRPS spec
      # to get differences - see 'Membership differences' section of NRPS spec
      # query parameter of '{"role" => "Learner"}'
      # will filter the memberships to just those which have a Learner role.
      # query parameter of '{"rlid" => "49566-rkk96"}' will filter the memberships to just those which
      # have access to the resource link with ID '49566-rkk96'
      def list(query: {}, page_url: nil)
        url = if page_url.present?
                page_url
              else
                uri = Addressable::URI.parse(endpoint)
                uri.query_values = (uri.query_values || {}).merge(query)
                uri
              end
        verify_received_user_names(
          HTTParty.get(
            url,
            headers: headers(
              {
                "Content-Type" => "application/vnd.ims.lti-nrps.v2.membershipcontainer+json",
              },
            ),
          ),
        )
      end

      def verify_received_user_names(names_and_roles_memberships)
        if names_and_roles_memberships.present?
          members = JSON.parse(names_and_roles_memberships.body)["members"]

          if members.present? && members.all? { |member| member["name"].nil? }
            raise(
              AtomicLti::Exceptions::NamesAndRolesError,
              "Unable to fetch user data. Your LTI key may be set to private.",
            )
          end
        end
        names_and_roles_memberships
      end
    end
  end
end
