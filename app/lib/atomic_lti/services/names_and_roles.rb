module AtomicLti
  module Services
    class NamesAndRoles < AtomicLti::Services::Base

      def initialize(id_token_decoded:)
        super(id_token_decoded: id_token_decoded)
      end

      def scopes
        [AtomicLti::Definitions::NAMES_AND_ROLES_SCOPE]
      end

      def endpoint
        url = @id_token_decoded.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM, "context_memberships_url")
        raise AtomicLti::Exceptions::NamesAndRolesError, "Unable to access names and roles" unless url.present?

        url
      end

      def url_for(query = nil)
        url = endpoint.dup
        url << "?#{query}" if query.present?
        url
      end

      def self.enabled?(id_token_decoded)
        return false unless id_token_decoded&.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM)

        (AtomicLti::Definitions::NAMES_AND_ROLES_SERVICE_VERSIONS &
          (id_token_decoded.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM, "service_versions") || [])).present?
      end

      def valid?
        self.class.enabled?(@id_token_decoded)
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
                uri.to_str
              end
        verify_received_user_names(
          HTTParty.get(
            url,
            headers: headers(
              {
                "Accept" => "application/vnd.ims.lti-nrps.v2.membershipcontainer+json",
              },
            ),
          ),
        )
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

      def verify_received_user_names(names_and_roles_memberships)
        if names_and_roles_memberships&.body.present?
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
