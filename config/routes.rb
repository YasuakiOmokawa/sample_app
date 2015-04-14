SampleApp::Application.routes.draw do
  # get "password_resets/new"
  # resources :users ,:except => [:index] do
  resources :users do
    member do
      get :search, :direct, :referral, :social, :campaign, :last, :all, :show_detail, :edit_detail, :edit_init_analyze
      post :show
      patch :update_detail, :update_init_analyze
      put :update_detail, :update_init_analyze
    end
  end
  resources :sessions, only: [:new, :create, :destroy]
  resources :password_resets
  root  'sessions#new'
  # root  'static_pages#home'
  match '/signup',  to: 'users#new', via: 'get'
  match '/signin',  to: 'sessions#new', via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'
  match '/help', to: 'static_pages#help', via: 'get'
  match '/about',   to: 'static_pages#about',   via: 'get'
  match '/contact', to: 'static_pages#contact', via: 'get'
end
