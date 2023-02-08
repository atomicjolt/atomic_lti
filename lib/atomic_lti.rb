require "atomic_lti/version"
require "atomic_lti/engine"
require "atomic_lti/open_id_middleware"
require "atomic_lti/error_handling_middleware"

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
  mattr_accessor :jwt_secret


  def self.get_deployments(iss:, deployment_ids:)
    AtomicLti::Deployment.where(iss: iss, deployment_id: deployment_ids)
  end

end
