require "atomic_lti/version"
require "atomic_lti/engine"

module AtomicLti

  # Set this to true to scope context_id's to the ISS rather than
  # to the deployment id.  We anticipate LMS's will work this
  # way, and it means that reinstalling into a course won't change
  # the context records.
  mattr_accessor :context_scope_to_iss
  @@context_scope_to_iss = true

end
