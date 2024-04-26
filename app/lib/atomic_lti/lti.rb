module AtomicLti
  class Lti

    def self.validate!(decoded_token, requested_target_link_uri = nil, validate_target_link_url = false)
      if decoded_token.blank?
        raise AtomicLti::Exceptions::InvalidLTIToken
      end

      errors = []

      if decoded_token["iss"].blank?
        errors.push("LTI token is missing required field iss")
      end

      if decoded_token["sub"].blank? && !AtomicLti.allow_anonymous_user
        errors.push("LTI token is missing required field sub")
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

      if decoded_token[AtomicLti::Definitions::MESSAGE_TYPE].blank?
        errors.push(
          "LTI token is missing required claim #{AtomicLti::Definitions::MESSAGE_TYPE}"
        )
      end

      if decoded_token[AtomicLti::Definitions::MESSAGE_TYPE] === "LtiResourceLinkRequest"
        errors.concat(validate_resource_link_request(decoded_token, requested_target_link_uri, validate_target_link_url))
      end

      if decoded_token[AtomicLti::Definitions::ROLES_CLAIM].blank?
        errors.push(
          "LTI token is missing required claim #{AtomicLti::Definitions::ROLES_CLAIM}"
        )
      end

      roles = decoded_token[AtomicLti::Definitions::ROLES_CLAIM]
      if AtomicLti.role_enforcement_mode == AtomicLti::RoleEnforcementMode::STRICT && roles.is_a?(Array) && !roles.empty?
        invalid_roles = roles - AtomicLti::Definitions::ROLES
        if invalid_roles.length == roles.length
          errors.push("LTI token has invalid roles: #{invalid_roles.join(", ")}")
        end
      end

      if errors.length > 0
        raise AtomicLti::Exceptions::InvalidLTIToken.new(errors.join(" "))
      end

      if decoded_token[AtomicLti::Definitions::LTI_VERSION].blank?
        raise AtomicLti::Exceptions::NoLTIVersion
      end

      raise AtomicLti::Exceptions::InvalidLTIVersion unless valid_version?(decoded_token)

      true
    end

    def self.validate_resource_link_request(decoded_token, requested_target_link_uri = nil, validate_target_link_url = false)
      errors = []

      if decoded_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM].blank?
        errors.push(
          "LTI token is missing required claim #{AtomicLti::Definitions::TARGET_LINK_URI_CLAIM}",
        )
      end

      # Validate that we are at the target_link_uri
      target_link_uri = decoded_token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]

      if validate_target_link_url &&
          !matching_uri?(target_link_uri, requested_target_link_uri, ignore_host: AtomicLti.update_target_link_host)
        errors.push(
          "LTI token target link uri '#{target_link_uri}' doesn't match url '#{requested_target_link_uri}'",
        )
      end

      if decoded_token[AtomicLti::Definitions::RESOURCE_LINK_CLAIM].blank?
        errors.push(
          "LTI token is missing required claim #{AtomicLti::Definitions::RESOURCE_LINK_CLAIM}",
        )
      end

      if decoded_token.dig(AtomicLti::Definitions::RESOURCE_LINK_CLAIM, "id").blank?
        errors.push(
          "LTI token is missing required field id from the claim #{AtomicLti::Definitions::RESOURCE_LINK_CLAIM}",
        )
      end

      errors
    end

    def self.valid_version?(decoded_token)
      if decoded_token[AtomicLti::Definitions::LTI_VERSION]
        decoded_token[AtomicLti::Definitions::LTI_VERSION].starts_with?("1.3")
      else
        false
      end
    end

    def self.client_id(decoded_token)
      if decoded_token["aud"]&.is_a?(Array)
        if decoded_token["aud"].length > 1
          decoded_token["azp"]
        else
          decoded_token["aud"][0]
        end
      else
        decoded_token["aud"]
      end
    end

    def self.matching_uri?(target, actual, ignore_host:)
      t = URI.parse(target)
      a = URI.parse(actual)

      t.scheme == a.scheme &&
        t.path == a.path &&
        t.query == a.query &&
        t.fragment == a.fragment &&
        (ignore_host || t.host == a.host)
    end
  end
end
