$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "atomic_lti/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "atomic_lti"
  s.version     = AtomicLti::VERSION
  s.authors     = ["Atomic Jolt", "Justin Ball"]
  s.email       = ["justin@atomicjolt.com"]
  s.homepage    = "http://www.github.com/atomicjolt/atomic_lti"
  s.summary     = "Atomic Jolt's Rails Engine for making LTI simple."
  s.description = "This is a Rails Engine that includes LTI functionality used to integrate with learning management systems."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.0.0"
  s.add_dependency "pg"
  s.add_dependency "ims-lti"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"

end
