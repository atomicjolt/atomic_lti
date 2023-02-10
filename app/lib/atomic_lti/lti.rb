module AtomicLti
  class Lti
    def self.validate!(decoded_token)
      if decoded_token.blank?
        raise AtomicLti::Exceptions::InvalidLTIToken
      end

      if decoded_token["iss"].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new("LTI token is missing required field iss")
      end

      if decoded_token["sub"].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new("LTI token is missing required field sub")
      end

      if decoded_token[AtomicLti::Definitions::DEPLOYMENT_ID].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required field #{AtomicLti::Definitions::DEPLOYMENT_ID}"
        )
      end

      if decoded_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required claim #{AtomicLti::Definitions::TARGET_LINK_URI_CLAIM}"
        )
      end

      if decoded_token[AtomicLti::Definitions::RESOURCE_LINK_CLAIM].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required claim #{AtomicLti::Definitions::RESOURCE_LINK_CLAIM}"
        )
      end

      if decoded_token[AtomicLti::Definitions::RESOURCE_LINK_CLAIM]["id"].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required field id from the claim #{AtomicLti::Definitions::RESOURCE_LINK_CLAIM}"
        )
      end

      if decoded_token[AtomicLti::Definitions::MESSAGE_TYPE].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required claim #{AtomicLti::Definitions::MESSAGE_TYPE}"
        )
      end

      if decoded_token[AtomicLti::Definitions::ROLES_CLAIM].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required claim #{AtomicLti::Definitions::ROLES_CLAIM}"
        )
      end

      if decoded_token[AtomicLti::Definitions::LTI_VERSION].blank?
        raise AtomicLti::Exceptions::NoLTIVersion
      end

      raise AtomicLti::Exceptions::InvalidLTIVersion unless valid_version?(decoded_token)
      true
    end

    def self.valid_version?(decoded_token)
      if decoded_token[AtomicLti::Definitions::LTI_VERSION]
        decoded_token[AtomicLti::Definitions::LTI_VERSION].starts_with?("1.3")
      else
        false
      end
    end
  end
end