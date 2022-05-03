# Add default jwk
AtomicLti::Jwk.find_or_create_by(domain: nil)

# Add some platforms
AtomicLti::Platform.create_with(
  jwks_url: "https://canvas.instructure.com/api/lti/security/jwks",
  token_url: "https://canvas.instructure.com/login/oauth2/token",
  oidc_url: "https://canvas.instructure.com/api/lti/authorize_redirect",
).find_or_create_by(iss: "https://canvas.instructure.com")

AtomicLti::Platform.create_with(
  jwks_url: "https://canvas-beta.instructure.com/api/lti/security/jwks",
  token_url: "https://canvas-beta.instructure.com/login/oauth2/token",
  oidc_url: "https://canvas-beta.instructure.com/api/lti/authorize_redirect",
).find_or_create_by(iss: "https://canvas-beta.instructure.com")

