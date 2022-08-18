require "atomic_lti/version"
require "atomic_lti/engine"
require "atomic_lti/open_id_middleware"

module AtomicLti

  # Set this to true to scope context_id's to the ISS rather than
  # to the deployment id.  We anticipate LMS's will work this
  # way, and it means that reinstalling into a course won't change
  # the context records.
  mattr_accessor :context_scope_to_iss
  @@context_scope_to_iss = true

  def self.jwt_issue_iss
     "atomicjoltapps.com"
  end

end
