require_relative "lib/atomic_lti/version"

Gem::Specification.new do |spec|
  spec.name        = "atomic_lti"
  spec.version     = AtomicLti::VERSION
  spec.authors     = ["Matt Petro"]
  spec.email       = ["matt.petro@atomicjolt.com"]
  spec.homepage    = "https://www.example.com" #TODO
  spec.summary     = "Summary of AtomicLti."
  spec.description = "Description of AtomicLti."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://www.example.com"
  spec.metadata["changelog_uri"] = "https://www.example.com"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 7.0.3"
end
