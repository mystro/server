MystroServer::Application.routes.draw do
  namespace :api do
    scope :defaults => { :format => 'json' } do
      resource :status
      resources :organizations do
        resources :organizations
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

  resources :organizations do
    post "select", :on => :member
  end

  resources :balancers
  resources :listeners

  resources :computes
  resources :roles

  resources :environments do
    post "refresh", on: :member
  end
  resources :templates

  resources :zones
  resources :records

  resources :userdata


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

  match "/home/widget/:environment" => "home#widget"
  match "/home/raw" => "home#raw"
  root :to => "home#index"

  mount Qujo::Engine => "/"
end
