module AtomicLti

  module DeepLinking

#   # ###########################################################
#   # Create a jwt to sign a response to the platform
    def self.create_deep_link_jwt(iss:, deployment_id:, content_items:, deep_link_claim_data: nil)
      deployment = AtomicLti::Deployment.find_by(iss: iss, deployment_id: deployment_id)

      raise AtomicLti::Exceptions::NoLTIDeployment if deployment.nil?

      install = deployment.install

      raise AtomicLti::Exceptions::NoLTIInstall if install.nil?

      payload = {
        iss: install.client_id, # A unique identifier for the entity that issued the JWT
        aud: iss, # Authorization server identifier
        iat: Time.now.to_i, # Timestamp for when the JWT was created
        exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
        # (after allowing a margin for clock skew)
        azp: install.client_id,
        nonce: SecureRandom.hex(10),
        AtomicLti::Definitions::MESSAGE_TYPE => "LtiDeepLinkingResponse",
        AtomicLti::Definitions::LTI_VERSION => "1.3.0",
        AtomicLti::Definitions::DEPLOYMENT_ID => deployment_id,
        AtomicLti::Definitions::CONTENT_ITEM_CLAIM => content_items
      }

      if deep_link_claim_data.present?
        payload[AtomicLti::Definitions::DEEP_LINKING_DATA_CLAIM] = deep_link_claim_data
      end

      AtomicLti::Authorization.sign_tool_jwt(payload)
    end
  end
end