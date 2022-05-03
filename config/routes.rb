AtomicLti::Engine.routes.draw do
  resources :launches do
    collection do
      post :index
      get :init
      post :init
      post :redirect
    end
    member do
      post :show
    end
  end
  resources :jwks
  resources :dynamic_registrations
end
