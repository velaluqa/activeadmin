Rails.application.routes.draw do
  match('app/*path', to: 'spa#index', via: :get)
  match('app', to: 'spa#index', via: :get)

  ActiveAdmin.routes(self)

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
  resources :images, only: [:create, :show] do
  end

  resources :images_search, only: [] do
    collection do
      get 'search'
    end
  end

  get 'wado' => 'wado#wado'

  namespace :v1 do
    get 'dashboard' => 'dashboard#index'

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

    resources :forms do
      resources(
        :form_answers,
        path: "answers",
        only: %i[show new create edit]
      )

      member do
        get :configuration
        get :current_configuration
        get :locked_configuration
      end
    end
    resources :form_answers do
      member do
        post :sign
        post :unblock
        get :viewer
      end
    end
    resources :form_sessions, only: %i[show]

    get 'report' => 'report#index'
  end

  # TODO: Removed in favor of WADOURI
  get(
    "/dicomweb/*scope/*scope_id/rs/studies/*study_uid/series/*series_uid/instances/*instance_uid/frames/*frame_number",
    to: "qido#query_frame"
  )
  get(
    "/dicomweb/*scope/*scope_id/rs/studies/*study_uid/series/*series_uid/instances",
    to: "qido#query_instances"
  )
  get(
    "/dicomweb/*scope/*scope_id/rs/studies/*study_uid/series/*series_uid/metadata",
    to: "qido#query_metadata"
    )
  get(
    "/dicomweb/*scope/*scope_id/rs/studies/*study_uid/series",
    to: "qido#query_series"
    )
  get(
    "/dicomweb/*scope/*scope_id/rs/studies",
    to: "qido#query_studies"
  )

  # Override paths to allow for client-side routing
  get "/admin/image_series/*id/viewer/*path", to: "admin/image_series#viewer"
  get "/admin/viewer_cart/viewer/*path", to: "admin/viewer_cart#viewer"
  get "/admin/visits/*id/viewer/*scope", to: "admin/visits#viewer"
  get "/admin/visits/*id/viewer/*scope/*path", to: "admin/visits#viewer"
  get "/v1/form_answers/*id/viewer/*path", to: "v1/form_answers#viewer"

  authenticate :user, ->(user) { user.can?(:manage, Sidekiq) } do
    require 'sidekiq/web'
    require 'sidekiq-scheduler/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root(to: redirect('/admin'))
end
