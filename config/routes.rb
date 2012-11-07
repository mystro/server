MystroServer::Application.routes.draw do
  mount Resque::Server.new, :at => "/admin/resque"
  resource :resque

  resources :balancers
  resources :listeners

  resources :computes
  resources :roles

  resources :environments
  resources :templates

  resources :zones
  resources :records

  #resources :providers
  #resources :accounts

  # DO NOT UNCOMMENT THIS FOR NOW
  # creates a redirect loop
  #resources :users, :only => [:show, :index]

  resource :profile, :only => [:edit, :show, :update]
  devise_for :users

  authenticated :user do
    root :to => 'home#index'
  end

  root :to => "home#index"
end
