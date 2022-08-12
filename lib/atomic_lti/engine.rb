module AtomicLti
  class Engine < ::Rails::Engine
    isolate_namespace AtomicLti

    initializer "atomic_lti.middleware" do |app|
      app.config.app_middleware.insert_before AtomicTenant::CurrentApplicationInstanceMiddleware, AtomicLti::OpenIdMiddleware
    end
  end
end
