require_relative "lib/atomic_lti/version"

Gem::Specification.new do |spec|
  spec.name        = "atomic_lti"
  spec.version     = AtomicLti::VERSION
  spec.authors     = ["Matt Petro", "Justin Ball", "Nick Benoit"]
  spec.email       = ["matt.petro@atomicjolt.com", "justin.ball@atomicjolt.com", "nick.benoit@atomicjolt.com"]
  spec.homepage    = "https://github.com/atomicjolt/atomic_lti"
  spec.summary     = "AtomicLti implements the LTI Advantage specification."
  spec.description = "AtomicLti implements the LTI Advantage specification. This gem does contain source code specific to other Atomic Jolt products"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/atomicjolt/atomic_lti"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "pg", ">= 1.3"
  spec.add_dependency "rails", "~> 7.0"
end
