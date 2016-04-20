# activeadmin-mongoid monkey-patches this method to always return false, thus disabling comments
# at the moment, because of foobar, we can't patch this in activeadmin-mongoid without also updating activeadmin-mongoid (to the version that will only work with the new activeadmin generation)
# long snafu short: it's currently easier to just re-monkey-patch-enable comments here than to fix activeadmin-mongoid... :(
ActiveAdmin::Namespace # autoload
class ActiveAdmin::Namespace
  # Reenable comments
  def comments?
    allow_comments == true
  end
end

StudyServer::Application.routes.draw do
  ActiveAdmin.routes(self)

  if ERICA.remote?
    get '/erica_remote/paths', to: 'erica_remote#paths'
  end

  resources :forms, only: [:show] do
    member do
      get 'previous_results'
      get 'preview'
    end
  end
  resources :form_answers, only: [:create]

  resources :sessions, only: [:show] do
    collection do
      get 'list'
    end
    member do
      get 'reserve_cases'
    end
  end

  resources :cases, only: [] do
    member do
      get 'cancel_read'
    end
  end

  devise_for :users, controllers: { sessions: 'users/sessions' }
  devise_scope :user do
    post 'users/authenticate', to: 'users/sessions#authenticate_user'
    get 'users/change_password', to: 'users#change_password'
    patch 'users/update_password', to: 'users#update_password'
    get 'users/uploader_rights', to: 'users#uploader_rights'
    get 'users/cancel_current_cases', to: 'users#cancel_current_cases'
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

  authenticate :user, ->(u) { u.is_app_admin? } do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root to: 'admin/dashboard#index'
end
