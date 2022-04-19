module AtomicLti
  class Authorization
    # Validates a token provided by an LTI consumer
    def self.validate_token(jwks_url, token)
      # Get the iss value from the original request during the oidc call.
      # Use that value to figure out which jwk we should use.
      decoded_token = JWT.decode(token, nil, false)
      iss = decoded_token.dig(0, "iss")
      cache_key = "#{iss}_jwks"

      jwk_loader = ->(options) do
        jwks = Rails.cache.read(cache_key)
        if options[:invalidate] || jwks.blank?
          deployment_id = decoded_token.dig(0, AtomicLti::Definitions::DEPLOYMENT_ID)
          lti_deployment = LtiDeployment.find_by(
            deployment_id: deployment_id,
          )
          if lti_deployment.blank?
            raise AtomicLti::Exceptions::NoLTIDeployment, "No LTI Deployment found with #{deployment_id}"
          end

          client_id = lti_deployment.lti_install.client_id
          jwks = JSON.parse(
            HTTParty.get(jwks_url).body,
          ).deep_symbolize_keys
          Rails.cache.write(cache_key, jwks, expires_in: 12.hours)
        end
        jwks
      end

      lti_token, _keys = JWT.decode(token, nil, true, { algorithms: ["RS256"], jwks: jwk_loader })
      lti_token
    end

    def self.sign_tool_jwt(current_jwk, payload)
      JWT.encode(payload, current_jwk.private_key, current_jwk.alg, kid: current_jwk.kid, typ: "JWT")
    end

    def self.client_assertion(current_jwk, iss, token_url, lti_token)
      # https://www.imsglobal.org/spec/lti/v1p3/#token-endpoint-claim-and-services
      # When requesting an access token, the client assertion JWT iss and sub must both be the
      # OAuth 2 client_id of the tool as issued by the learning platform during registration.
      # Additional information:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant

      lti_deployment = LtiDeployment.find_by(deployment_id: lti_token[AtomicLti::Definitions::DEPLOYMENT_ID])
      lti_install = lti_deployment.lti_install

      payload = {
        iss: iss, # A unique identifier for the entity that issued the JWT
        sub: lti_install.client_id, # "client_id" of the OAuth Client
        aud: token_url, # Authorization server identifier
        iat: Time.now.to_i, # Timestamp for when the JWT was created
        exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
        # (after allowing a margin for clock skew)
        jti: SecureRandom.hex(10), # A unique (potentially reusable) identifier for the token
      }
      sign_tool_jwt(current_jwk, payload)
    end

    def self.request_token(current_jwk, iss, token_url, lti_token, lti_token)
      lti_user_id = lti_token["sub"]
      cache_key = "#{lti_user_id}_authorization"

      authorization = Rails.cache.read(cache_key)
      return authorization if authorization.present?

      # Details here:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant
      body = {
        grant_type: "client_credentials",
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        scope: AtomicLti::Definitions.scopes.join(" "),
        client_assertion: client_assertion(current_jwk, iss, token_url, lti_token),
      }
      headers = {
        "Content-Type" => "application/x-www-form-urlencoded",
      }

      lti_deployment = LtiDeployment.find_by(
        deployment_id: lti_token[AtomicLti::Definitions::DEPLOYMENT_ID],
      )
      client_id = lti_deployment.lti_install.client_id
      result = HTTParty.post(token_url, body: body, headers: headers)
      authorization = JSON.parse(result.body)

      Rails.cache.write(cache_key, authorization, expires_in: authorization["expires_in"].to_i)

      authorization
    end
  end
end
