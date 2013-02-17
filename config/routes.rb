MystroServer::Application.routes.draw do

  mount Resque::Server.new, :at => "/admin/resque"
  resource :resque

  namespace :api do
    scope :defaults => { :format => 'json' } do
      resources :accounts do
        resources :accounts
        resources :environments
        resources :computes do
          collection do
            match "search", :to => "computes#search"
            match "search/:pattern", :to => "computes#search", :constraints => { :pattern => /[0-9A-Za-z\-\.\,]+/ }
          end
        end
        resources :templates
      end
    end
  end

  resources :accounts do
    post "select", :on => :member
  end

  resources :balancers
  resources :listeners

  resources :computes
  resources :roles

  resources :environments
  resources :templates

  resources :zones
  resources :records

  resources :userdata
  resources :jobs do
    post "refresh", on: :member
  end


  #resources :providers

  # DO NOT UNCOMMENT THIS FOR NOW
  # creates a redirect loop
  resources :users

  resource :profile, :only => [:edit, :show, :update]
  #devise_for :users
  devise_for :users, :path => "auth", :path_names => { :sign_in => 'login', :sign_out => 'logout' }

  authenticated :user do
    root :to => 'home#index'
  end

  root :to => "home#index"
end
