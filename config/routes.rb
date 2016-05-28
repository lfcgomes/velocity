Rails.application.routes.draw do
  resources :homes
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'homes#index'

  resources :directions, only: :index
  resources :traffic, only: :index
  resources :environment, only: :index
end
