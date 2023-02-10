module AtomicLti
  class Lti
    def self.validate!(decoded_token)
      if decoded_token.blank?
        raise AtomicLti::Exceptions::InvalidLTIToken
      end

      if decoded_token["iss"].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new("LTI token is missing required field iss")
      end

      if decoded_token[AtomicLti::Definitions::DEPLOYMENT_ID].blank?
        raise AtomicLti::Exceptions::InvalidLTIToken.new(
          "LTI token is missing required field #{AtomicLti::Definitions::DEPLOYMENT_ID}"
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