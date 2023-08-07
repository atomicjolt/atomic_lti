# Add default jwk
AtomicLti::Jwk.find_or_create_by(domain: nil)

# Add some platforms
AtomicLti::Platform.create_with(
  jwks_url: AtomicLti::Definitions::CANVAS_PUBLIC_LTI_KEYS_URL,
  token_url: AtomicLti::Definitions::CANVAS_AUTH_TOKEN_URL,
  oidc_url: AtomicLti::Definitions::CANVAS_OIDC_URL,
).find_or_create_by(iss: "https://canvas.instructure.com")

AtomicLti::Platform.create_with(
  jwks_url: AtomicLti::Definitions::CANVAS_BETA_PUBLIC_LTI_KEYS_URL,
  token_url: AtomicLti::Definitions::CANVAS_BETA_AUTH_TOKEN_URL,
  oidc_url: AtomicLti::Definitions::CANVAS_BETA_OIDC_URL,
).find_or_create_by(iss: "https://canvas-beta.instructure.com")


AtomicLti::Install.create_with(iss: "https://canvas.instructure.com").find_or_create_by(client_id: "43460000000000525")

AtomicTenant::PinnedPlatformGuid.create(iss: "https://canvas.instructure.com", platform_guid: "4MRcxnx6vQbFXxhLb8005m5WXFM2Z2i8lQwhJ1QT:canvas-lms", application_id: 6, application_instance_id: 5)


# => #<AtomicTenant::LtiDeployment:0x00000001294e6018
#  id: 1,
#  iss: "https://canvas.instructure.com",
#  deployment_id: "21089:1f5e1ee417cb2b17f86a1232122452ab3f6188f7",
#  application_instance_id: 5,
#  created_at: Tue, 16 Aug 2022 16:05:20.848365000 UTC +00:00,
#  updated_at: Tue, 16 Aug 2022 16:05:20.848365000 UTC +00:00>