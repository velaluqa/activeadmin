StudyServer::Application.routes.draw do
  ActiveAdmin.routes(self)

  resources :forms, :only => [:show] do
    member do
      get 'previous_results'
      get 'preview'
    end
  end
  resources :form_answers, :only => [:create]

  resources :sessions, :only => [:show] do
    collection do
      get 'list'
    end
    member do
      get 'reserve_cases'
    end
  end
  
  resources :cases, :only => [] do
    member do
      get 'cancel_read'
    end
  end

  devise_for :users, :controllers => { :sessions => 'users/sessions' }
  devise_scope :user do
    post 'users/authenticate', :to => 'users/sessions#authenticate_user'
    get 'users/change_password', :to => 'users#change_password'
    put 'users/update_password', :to => 'users#update_password'
  end

  resources :studies, :only => [:index] do
    resources :centers, :only => [:index]
  end

  resources :centers, :only => [:create] do
    resources :patients, :only => [:index]
  end

  resources :patients, :only => [:create] do
    resources :image_series, :only => [:index]
  end

  resources :image_series, :only => [:create] do
    member do
      get 'wado_query'
    end
  end
  resources :images, :only => [:create] do
    collection do
      post 'batch_create'
    end
  end

  match 'wado' => 'wado#wado'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'admin/dashboard#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
