Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  get '/erica_remote/paths', to: 'erica_remote#paths' if ERICA.remote?

  devise_for :users, controllers: { sessions: 'users/sessions' }
  devise_scope :user do
    post 'users/authenticate', to: 'users/sessions#authenticate_user'
    get 'users/change_password', to: 'users#change_password'
    patch 'users/update_password', to: 'users#update_password'
    get 'users/ensure_keypair', to: 'users#ensure_keypair'
    patch 'users/create_keypair', to: 'users#create_keypair'
    get 'users/uploader_rights', to: 'users#uploader_rights'
  end

  resources :studies, only: [:index] do
    resources :centers, only: [:index]

    member do
      get 'wado_query'
    end
  end

  resources :centers, only: [:create] do
    resources :patients, only: [:index]

    member do
      get 'wado_query'
    end
  end

  resources :patients, only: [:create] do
    resources :image_series, only: [:index]

    member do
      get 'wado_query'
    end
  end

  resources :visits, only: [] do
    member do
      get 'wado_query'
      get 'required_series_wado_query'
    end
  end

  resources :image_series, only: [:create] do
    member do
      get 'wado_query'
    end
  end
  resources :images, only: [:create] do
  end

  resources :images_search, only: [] do
    collection do
      get 'search'
    end
  end

  get 'wado' => 'wado#wado'

  namespace :v1 do
    resources :images
    resources :image_series do
      member do
        post :finish_import
        post :assign_required_series
      end
    end
    resources :patients do
      resources :visits
    end
    resources :visits

    resources :search

    get 'report' => 'report#index'
  end

  authenticate :user, ->(user) { user.can?(:manage, Sidekiq) } do
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root to: 'admin/dashboard#index'
end
