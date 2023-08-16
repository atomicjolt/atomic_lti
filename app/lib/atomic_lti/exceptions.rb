module AtomicLti
  module Exceptions

    # LTI data related exceptions
    class AtomicLtiException < StandardError
    end

    class LineItemError < AtomicLtiException
    end

    class ConfigurationError < AtomicLtiException
    end

    class NamesAndRolesError < AtomicLtiException
    end

    class ScoreError < AtomicLtiException
    end

    class StateError < AtomicLtiException
    end

    class OpenIDRedirectError < AtomicLtiException
    end

    class LineItemMissing < LineItemError
    end

    class RateLimitError < AtomicLtiException
    end

    class LtiConfigMissing < AtomicLtiException
    end

    class InvalidLTIVersion < AtomicLtiException
      def initialize(msg = "Invalid LTI version")
        super(msg)
      end
    end

    class NoLTIVersion < AtomicLtiException
      def initialize(msg = "No LTI Version provided")
        super(msg)
      end
    end

    # Authorization errors
    class AtomicLtiAuthException < StandardError
    end

    class InvalidLTIToken < AtomicLtiAuthException
      def initialize(msg = "Invalid LTI token provided")
        super(msg)
      end
    end

    class JwtIssueError < AtomicLtiAuthException
    end

    class NoLTIToken < AtomicLtiAuthException
      def initialize(msg = "No LTI token provided")
        super(msg)
      end
    end

    class OpenIDStateError < AtomicLtiAuthException
    end

    # Not found exceptions
    class AtomicLtiNotFoundException < StandardError
    end

    class NoLTIDeployment < AtomicLtiNotFoundException
      def initialize(iss:, deployment_id:)
        msg = "No LTI Deployment found for iss: #{iss} and deployment_id #{deployment_id}"
        super(msg)
      end
    end

    class NoLTIInstall < AtomicLtiNotFoundException
      def initialize(iss:, deployment_id:)
        msg = "No LTI Install found for iss: #{iss} and deployment_id #{deployment_id}"
        super(msg)
      end
    end

    class NoLTIPlatform < AtomicLtiNotFoundException
      def initialize(iss:, deployment_id: nil)
        msg = "No LTI Platform associated with the LTI Install. iss: #{iss}"
        if iss && deployment_id
          msg = "No LTI Platform associated with the LTI Install. iss: #{iss} and deployment_id #{deployment_id}"
        end
        super(msg)
      end
    end
  end
end
