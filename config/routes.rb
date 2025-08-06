Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  
  # Custom Devise routes for better UX
  devise_scope :user do
    get '/signup', to: 'devise/registrations#new'
    get '/signin', to: 'devise/sessions#new'
    get '/login', to: 'users/sessions#new'
    delete '/signout', to: 'users/sessions#destroy'
    delete '/logout', to: 'users/sessions#destroy'
  end
  
  # Root route - show home page for guests, dashboard for authenticated users
  root 'home#index'
  
  # About Us page
  get 'about', to: 'home#about'
  
  # Dashboard routes
  get '/dashboard', to: 'dashboard#index'
  get 'dashboard/analytics', to: 'dashboard#analytics'
  get 'dashboard/quick_stats', to: 'dashboard#quick_stats'

  # Profile routes
  resources :profiles, param: :username do
    member do
      get :similar
    end
    collection do
      get :search
      get :analytics
    end
  end
  
  # User profile routes (alternative routing)
  get '/users/:username', to: 'profiles#show', as: :user_profile
  
  # Notifications
  resources :notifications do
    member do
      patch :mark_as_read
      patch :mark_as_unread
    end
    collection do
      patch :mark_all_as_read
      delete :clear_all
      get :recent
      get :preferences
      post :preferences
      post :test_notification # Only in development
    end
  end
  
  # Posts routes
  resources :posts do
    resources :comments, except: [:show, :index]
    member do
      post :publish
      post :unpublish
      get :unpublish # Temporary fallback for debugging
      get :confirm_delete
    end
    collection do
      get :my_posts
      get :search
      get :simple_test
      get :test_simple
    end
  end
  
  # Standalone Comments routes
  resources :comments, only: [:edit, :update, :destroy] do
    member do
      post :report
    end
    collection do
      get :my_comments
    end
  end
  
  # User Activities
  resources :user_activities, only: [:index, :show] do
    collection do
      get :analytics
    end
  end
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Posts API
      resources :posts, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :publish
          post :unpublish
        end
        collection do
          get :my_posts
          get :search
        end
      end
      
      # User API
      resources :users, only: [:index, :show] do
        member do
          get :activities
          get :notifications
          get :posts
        end
      end
      
      # Dashboard API
      get 'dashboard/stats', to: 'dashboard#stats'
      get 'dashboard/analytics', to: 'dashboard#analytics'
      
      # Notifications API
      resources :notifications, only: [:index, :show, :update, :destroy]
      
      # Search API
      get 'search/users', to: 'search#users'
      get 'search/posts', to: 'search#posts'
      get 'search/global', to: 'search#global'
    end
  end
  
  # Search routes
  get 'search', to: 'search#index'
  get 'search/users', to: redirect('/profiles')
  
  # Direct uploads for Active Storage (for Trix image uploads)
  resources :direct_uploads, only: [:create]
  
  # Health check
  get 'health', to: 'health#check'
end
