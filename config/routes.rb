Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get    "/login",    to: "sessions#new",           as: :login
  post   "/login",    to: "sessions#create"
  delete "/logout",   to: "sessions#destroy",       as: :logout

  get    "/signup",   to: "registrations#new",      as: :signup
  post   "/signup",   to: "registrations#create"

  get    "/auth/:provider/callback", to: "sessions#omniauth"
  get    "/auth/failure",            to: "sessions#omniauth_failure"

  root to: "home#index"

  resource :profile, only: [ :edit, :update ]

  namespace :admin do
    root to: "dashboard#index"
    resources :productions,   only: [ :index, :new, :create, :destroy ]
    resources :distributions, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :users,         only: [ :index, :new, :create, :edit, :update, :destroy ]
  end

  resources :bike_requests,  only: [ :edit, :update ] do
    patch :complete_all, on: :member
  end
  resources :bikes,          only: [ :update ]
  resources :productions,    only: [ :show ] do
    get :tickets,   on: :member
    get :users,     on: :member
    get :inventory, on: :member
    get :members,   on: :member
    get :delivery,  on: :member
    get :your_tickets, on: :member
    resources :donors,           only: [ :index, :new, :create, :edit, :update ]
    resources :bike_requests,    only: [ :new, :create ]
    resources :user_productions, only: [ :create, :update, :destroy ]
  end
  resources :production_inventories, only: [ :update ]
  resources :distributions,  only: [ :show ] do
    get :tickets, on: :member
    get :users,   on: :member
    resources :bike_requests,      only: [ :new, :create ]
    resources :user_distributions, only: [ :create, :update, :destroy ]
  end
end
