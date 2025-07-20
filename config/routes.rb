Rails.application.routes.draw do
  resources :products
  resources :redemptions
  resources :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  get "users/:id/point_balance", to: "users#point_balance"

  # post "/redemptions/redeem_with_points", to: "redemptions#redeem_with_points"

  get "/users/:id/redemptions", to: "redemptions#user_history"

  get "users/:id/vip_grade", to: "users#vip_grade"

  resources :redemptions do
    collection do
      post :redeem_with_points
    end
  end

  post "/purchases/start_stripe_payment", to: "purchases#start_stripe_payment"

  post "/stripe/webhook", to: "stripe_webhooks#receive"
end
