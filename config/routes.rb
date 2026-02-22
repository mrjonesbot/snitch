Snitch::Engine.routes.draw do
  resources :snitches, only: [:index, :show, :update]
  root to: "snitches#index"
end
