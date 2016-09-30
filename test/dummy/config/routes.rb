Rails.application.routes.draw do
  mount AtomicLti::Engine => "/atomic_lti"
end
