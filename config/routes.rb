StudyServer::Application.routes.draw do
  ActiveAdmin.routes(self)

  if ERICA.remote?
    get '/erica_remote/paths', to: 'erica_remote#paths'
  end

  devise_for :users, controllers: { sessions: 'users/sessions' }
  devise_scope :user do
    post 'users/authenticate', to: 'users/sessions#authenticate_user'
    get 'users/change_password', to: 'users#change_password'
    patch 'users/update_password', to: 'users#update_password'
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

  authenticate :user, ->(user) { user.can?(:manage, Sidekiq) } do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root to: 'admin/dashboard#index'
end
