module AtomicLti

  module DeepLinking

#   # ###########################################################
#   # Create a jwt to sign a response to the platform
  def self.create_deep_link_jwt(jwt_token:, content_items:)
    token = jwt_token
    platform_iss = token["iss"]

    deployment = AtomicLti::Deployment.find_by(iss: platform_iss, deployment_id: token["deployment_id"])

    raise AtomicLti::Exceptions::NoLTIDeployment if deployment.nil?

    install = deployment.install

    raise AtomicLti::Exceptions::NoLTIInstall if install.nil?

    payload = {
      iss: install.client_id, # A unique identifier for the entity that issued the JWT
      aud: platform_iss, # Authorization server identifier
      iat: Time.now.to_i, # Timestamp for when the JWT was created
      exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
      # (after allowing a margin for clock skew)
      azp: install.client_id,
      nonce: SecureRandom.hex(10),
      AtomicLti::Definitions::MESSAGE_TYPE => "LtiDeepLinkingResponse",
      AtomicLti::Definitions::LTI_VERSION => "1.3.0",
      AtomicLti::Definitions::DEPLOYMENT_ID => token["deployment_id"],
      AtomicLti::Definitions::CONTENT_ITEM_CLAIM => content_items
    }

    if token["data"].present?
      payload[AtomicLti::Definitions::DEEP_LINKING_DATA_CLAIM] = token["data"]
    end

    AtomicLti::Authorization.sign_tool_jwt(payload)
    end
  end
end