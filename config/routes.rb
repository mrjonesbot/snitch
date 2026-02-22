Snitch::Engine.routes.draw do
  resources :snitches, only: [:index, :show, :update]
  post "webhooks/github", to: "webhooks#github"
  root to: "snitches#index"
end
