require 'ims/lti'
require 'oauth/request_proxy/rack_request'

module AtomicLti
  class Engine < ::Rails::Engine
    config.autoload_once_paths += Dir["#{config.root}/lib/**/"]

    isolate_namespace AtomicLti

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end

  end
end
