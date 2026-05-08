Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "dashboard", to: "dashboard#index"

    resources :decks

    get "decks/:deck_id/cards", to: "cards#index"
    post "decks/:deck_id/cards", to: "cards#create"
    delete "cards/:id", to: "cards#destroy"
    patch "cards/:id", to: "cards#update"
    post "cards/:id/done", to: "cards#done"

    post "generate_cards", to: "generate_cards#create"

    post "auth/google_oauth2/callback", to: "authentications#google_oauth2"

    resources :users, only: [ :create ]

    post "/login", to: "sessions#create"

    post "/password/forgot", to: "password#forgot"
    post "/password/validate-token", to: "password#validate_token"
    post "/password/reset", to: "password#reset_password"
  end
end
