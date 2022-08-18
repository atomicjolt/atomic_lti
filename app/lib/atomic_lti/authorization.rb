module AtomicLti
  class Authorization
    # Validates a token provided by an LTI consumer
    def self.validate_token(token)
      # Get the iss value from the original request during the oidc call.
      # Use that value to figure out which jwk we should use.
      decoded_token = JWT.decode(token, nil, false)
      iss = decoded_token.dig(0, "iss")
      client_id = decoded_token.dig(0, "aud")

      install = Install.find_by(iss: iss, client_id: client_id)

      raise AtomicLti::Exceptions::NoLTIInstall if install.nil?

      platform = install.platform

      raise AtomicLti::Exceptions::NoLTIPlatform if platform.nil?

      cache_key = "#{iss}_jwks"

      jwk_loader = ->(options) do
        jwks = Rails.cache.read(cache_key)
        if options[:invalidate] || jwks.blank?
          jwks = JSON.parse(
            HTTParty.get(platform.jwks_url).body,
          ).deep_symbolize_keys
          Rails.cache.write(cache_key, jwks, expires_in: 12.hours)
        end
        jwks
      end

      lti_token, _keys = JWT.decode(token, nil, true, { algorithms: ["RS256"], jwks: jwk_loader })
      lti_token
    end

    def self.sign_tool_jwt(application_instance, payload)
      jwk = application_instance.application.current_jwk
      JWT.encode(payload, jwk.private_key, jwk.alg, kid: jwk.kid, typ: "JWT")
    end

    def self.client_assertion(lti_deployment)
      # https://www.imsglobal.org/spec/lti/v1p3/#token-endpoint-claim-and-services
      # When requesting an access token, the client assertion JWT iss and sub must both be the
      # OAuth 2 client_id of the tool as issued by the learning platform during registration.
      # Additional information:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant

      lti_install = lti_deployment.lti_install
      application_instance = lti_deployment.application_instance

      payload = {
        iss: application_instance.lti_key, # A unique identifier for the entity that issued the JWT
        sub: lti_install.client_id, # "client_id" of the OAuth Client
        aud: application_instance.token_url(lti_install.iss, lti_install.client_id), # Authorization server identifier
        iat: Time.now.to_i, # Timestamp for when the JWT was created
        exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
        # (after allowing a margin for clock skew)
        jti: SecureRandom.hex(10), # A unique (potentially reusable) identifier for the token
      }
      sign_tool_jwt(application_instance, payload)
    end

    def self.request_token(lti_deployment)
      cache_key = "#{lti_deployment.cache_key_with_version}/services_authorization"
      authorization = Rails.cache.read(cache_key)
      return authorization if authorization.present?

      authorization = request_token_uncached(lti_deployment)

      # Subtract a few seconds so we don't use an expired token
      expires_in = authorization["expires_in"].to_i - 10

      Rails.cache.write(
        cache_key,
        authorization,
        expires_in: expires_in,
      )

      authorization
    end

    def self.request_token_uncached(lti_deployment)
      # Details here:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant
      body = {
        grant_type: "client_credentials",
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        scope: AtomicLti::Definitions.scopes.join(" "),
        client_assertion: client_assertion(lti_deployment),
      }
      headers = {
        "Content-Type" => "application/x-www-form-urlencoded",
      }

      client_id = lti_deployment.lti_install.client_id
      iss = lti_deployment.lti_install.iss
      result = HTTParty.post(
        lti_deployment.application_instance.token_url(iss, client_id),
        body: body,
        headers: headers,
      )
      raise AtomicLti::Exceptions::OAuthError if !result.success?

      JSON.parse(result.body)
    end

  end
end
