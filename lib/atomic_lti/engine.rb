module AtomicLti
  class Engine < ::Rails::Engine
    isolate_namespace AtomicLti

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "atomic_lti.assets.precompile" do |app|
      app.config.assets.precompile += %w(init.js redirect.js application.css jwks.css launch.css)
    end
  end
end
