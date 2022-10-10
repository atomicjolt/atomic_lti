module AtomicLti
  class Engine < ::Rails::Engine
    isolate_namespace AtomicLti

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
