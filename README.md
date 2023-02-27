# AtomicLti
Atomic LTI implements the LTI Advantage specification.

## Usage
Add the gem:

  `gem 'atomic_lti', git: 'https://github.com/atomicjolt/atomic_lti.git', tag: '1.0.9'`

Add an initializer
  `config/initializers/atomic_lti.rb`

with the following contents. Adjust paths as needed.

  `
  AtomicLti.oidc_init_path = "/oidc/init"
  AtomicLti.oidc_redirect_path = "/oidc/redirect"
  AtomicLti.target_link_path_prefixes = ["/lti_launches"]
  AtomicLti.default_deep_link_path = "/lti_launches"
  AtomicLti.jwt_secret = Rails.application.secrets.auth0_client_secret
  AtomicLti.scopes = AtomicLti::Definitions.scopes.join(" ")
  `

