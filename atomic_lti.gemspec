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

  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "json-jwt"
  spec.add_runtime_dependency "jwt"
  spec.add_runtime_dependency "pg", "~> 1.3"
  spec.add_runtime_dependency "rails", "~> 7.0"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "webmock"

  spec.add_development_dependency "launchy"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"

  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "pronto"
  spec.add_development_dependency "pronto-rubocop"
end
