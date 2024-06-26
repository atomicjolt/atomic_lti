require "jwt"

module AtomicLti
  class Authorization

    AUTHORIZATION_TRIES = 3
    # Validates a token provided by an LTI consumer
    def self.validate_token(id_token)
      # Get the iss value from the original request during the oidc call.
      # Use that value to figure out which jwk we should use.
      decoded_token = JWT.decode(id_token, nil, false)

      iss = decoded_token.dig(0, "iss")

      raise AtomicLti::Exceptions::InvalidLTIToken.new("LTI token is missing iss") if iss.blank?

      platform = Platform.find_by(iss: iss)

      raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: iss, deployment_id: decoded_token.dig(0, "deployment_id")) if platform.nil?

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

      id_token_decoded, _keys = JWT.decode(id_token, nil, true, { algorithms: ["RS256"], jwks: jwk_loader })
      id_token_decoded
    end

    def self.sign_tool_jwt(payload)
      jwk = Jwk.current_jwk
      JWT.encode(payload, jwk.private_key, jwk.alg, kid: jwk.kid, typ: "JWT")
    end

    def self.client_assertion(iss:, deployment_id:)
      # https://www.imsglobal.org/spec/lti/v1p3/#token-endpoint-claim-and-services
      # When requesting an access token, the client assertion JWT iss and sub must both be the
      # OAuth 2 client_id of the tool as issued by the learning platform during registration.
      # Additional information:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant

      # lti_install = lti_deployment.lti_install

      deployment = AtomicLti::Deployment.find_by(iss: iss, deployment_id: deployment_id)

      raise AtomicLti::Exceptions::NoLTIDeployment.new(iss: iss, deployment_id: deployment_id) if deployment.nil?

      install = deployment.install

      raise AtomicLti::Exceptions::NoLTIInstall.new(iss: iss, deployment_id: deployment_id) if install.nil?

      platform = install.platform

      raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: iss, deployment_id: deployment_id) if platform.nil?

      payload = {
        iss:  install.client_id,  # A unique identifier for the entity that issued the JWT
        sub: install.client_id, # "client_id" of the OAuth Client
        aud: [platform.authorization_server || platform.token_url], # Authorization server identifier
        iat: Time.now.to_i, # Timestamp for when the JWT was created
        exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
        # (after allowing a margin for clock skew)
        jti: SecureRandom.hex(10), # A unique (potentially reusable) identifier for the token
      }
      sign_tool_jwt(payload)
    end

    def self.request_token(iss:, deployment_id:, scopes: nil)
      deployment = AtomicLti::Deployment.find_by(iss: iss, deployment_id: deployment_id)

      raise AtomicLti::Exceptions::NoLTIDeployment.new(iss: iss, deployment_id: deployment_id) if deployment.nil?

      scopestr = if scopes
                   scopes.sort.join(" ")
                 else
                   AtomicLti.scopes
                 end

      # Token is cached based on deployment id and requested scopes
      cache_key = "#{deployment.cache_key}/#{Digest::SHA1.hexdigest(scopestr)}/services_authorization"
      tries = 1

      begin
        authorization = Rails.cache.read(cache_key)
        return authorization if authorization.present?

        authorization = request_token_uncached(iss: iss, deployment_id: deployment_id, scopes: scopestr)

        # Subtract a few seconds so we don't use an expired token
        expires_in = authorization["expires_in"].to_i - 10

        Rails.cache.write(
          cache_key,
          authorization,
          expires_in: expires_in,
        )

      rescue AtomicLti::Exceptions::RateLimitError => e
        if tries < AUTHORIZATION_TRIES
          Rails.logger.warn("LTI Request token error: Rate limit exception, sleeping")
          sleep rand(1.0..2.0)
          tries += 1
          retry
        else
          raise e
        end
      end
      authorization
    end

    def self.request_token_uncached(iss:, deployment_id:, scopes:)
      # Details here:
      # https://www.imsglobal.org/spec/security/v1p0/#using-json-web-tokens-with-oauth-2-0-client-credentials-grant
      body = {
        grant_type: "client_credentials",
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        scope: scopes,
        client_assertion: client_assertion(iss: iss, deployment_id: deployment_id),
      }
      headers = {
        "Content-Type" => "application/x-www-form-urlencoded",
      }

      deployment = AtomicLti::Deployment.find_by(iss: iss, deployment_id: deployment_id)

      raise AtomicLti::Exceptions::NoLTIDeployment.new(iss: iss, deployment_id: deployment_id) if deployment.nil?

      platform = deployment.platform

      raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: iss, deployment_id: deployment_id) if platform.nil?

      result = HTTParty.post(
        platform.token_url,
        body: body,
        headers: headers
      )

      if !result.success?
        Rails.logger.warn(result.body)

        # Canvas rate limit error
        raise AtomicLti::Exceptions::RateLimitError if /rate limit/i.match?(result.body)

        raise AtomicLti::Exceptions::JwtIssueError.new(result.body)
      end

      JSON.parse(result.body)
    end

  end
end
