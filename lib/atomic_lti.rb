require "atomic_lti/version"
require "atomic_lti/engine"
require "atomic_lti/open_id_middleware"
require "atomic_lti/error_handling_middleware"
require_relative "../app/lib/atomic_lti/definitions"
require_relative "../app/lib/atomic_lti/exceptions"
require_relative "../app/lib/atomic_lti/role_enforcement_mode"
module AtomicLti

  # Set this to true to scope context_id's to the ISS rather than
  # to the deployment id.  We anticipate LMS's will work this
  # way, and it means that reinstalling into a course won't change
  # the context records.
  mattr_accessor :context_scope_to_iss
  @@context_scope_to_iss = true

  mattr_accessor :oidc_init_path
  mattr_accessor :oidc_redirect_path
  mattr_accessor :target_link_path_prefixes
  mattr_accessor :default_deep_link_path
  mattr_accessor :jwt_secret
  mattr_accessor :scopes, default: AtomicLti::Definitions.scopes.join(" ")

  # Set to true to enforce CSRF protection, either via cookies or postMessage
  mattr_accessor :enforce_csrf_protection, default: true

  # Set to true to use LTI postMessage storage for csrf token storage
  # with this enabled we can operate without cookies
  mattr_accessor :use_post_message_storage, default: true

  # Set to true to set the targetOrigin on postMessage calls. The LTI spec
  # requires this, but Canvas doesn't currently support it.
  mattr_accessor :set_post_message_origin, default: false

  mattr_accessor :privacy_policy_url, default: "#"
  mattr_accessor :privacy_policy_message, default: nil

  # https://www.imsglobal.org/spec/lti/v1p3#anonymous-launch-case
  # 'anonymous' here means that the launch does not include a 'sub' field. In
  # Canvas, this means the user is not logged in at all. If you enable this
  # option, you will likely have to adjust application code to accommodate
  mattr_accessor :allow_anonymous_user, default: false

  # https://www.imsglobal.org/spec/lti/v1p3#role-vocabularies
  # Determines how strictly to enforce the role vocabulary. The options are:
  # - "DEFAULT" which means that unknown roles are allowed to be the only roles in the token.
  # - "STRICT" which means that unknown roles are not allowed to be the only roles in the token.
  mattr_accessor :role_enforcement_mode, default: AtomicLti::RoleEnforcementMode::DEFAULT

  def self.get_deployments(iss:, deployment_ids:)
    AtomicLti::Deployment.where(iss: iss, deployment_id: deployment_ids)
  end

end
