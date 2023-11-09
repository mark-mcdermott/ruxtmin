Rails.application.routes.draw do
  resources :users
  get "health", to: "health#index"
  post "login", to: "authentications#create"
  get "me", to: "application#user_from_token"
end