Rails.application.routes.draw do
  require "sidekiq/web"

  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  else
    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/sidekiq"
    end
  end

  # Authentication routes - standard Devise
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    registration: "signup"
  },
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Custom routes for single-page application
  devise_scope :user do
    get "login", to: "users/sessions#new"
    get "signup", to: "users/registrations#new"
  end

  # Homepage route
  root "home#index"

  # Portfolio routes
  get "portfolio", to: "portfolio#index"
  get "portfolio/new", to: "portfolio#new", as: "new_portfolio"
  post "portfolio/create", to: "portfolio#create", as: "portfolio_create"
  get "portfolio/transactions", to: "portfolio#transactions", as: "portfolio_transactions"
  get "portfolio/add_more", to: "portfolio#add_more", as: "add_more_portfolio"
  post "portfolio/add_transaction", to: "portfolio#add_transaction", as: "add_transaction_portfolio"
  get "portfolio/sell", to: "portfolio#sell", as: "sell_portfolio"
  post "portfolio/create_sell", to: "portfolio#create_sell", as: "create_sell_portfolio"
  get "portfolio/transactions/:id/edit", to: "portfolio#edit_transaction", as: "edit_transaction_portfolio"
  post "portfolio/transactions/:id", to: "portfolio#update_transaction", as: "update_transaction_portfolio"
  put "portfolio/transactions/:id", to: "portfolio#update_transaction"
  delete "portfolio/transactions/:id", to: "portfolio#delete_transaction", as: "delete_transaction_portfolio"

  # Admin routes
  get "admin/trigger_price_update", to: "admin#trigger_price_update", as: "trigger_price_update"

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"

      # Asset routes
      resources :assets, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          get "value"
        end
      end

      # Transaction routes
      resources :transactions, only: [ :index, :show, :create ]
    end
  end

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "posts#index"
end
