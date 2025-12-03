Rails.application.routes.draw do
  namespace :admin do
      resources :admin_users
      resources :companies
      resources :delivery_companies
      resources :delivery_sheet_items
      resources :drivers
      resources :menus
      resources :orders do
        collection do
          get :calendar
          get :schedule
          patch :update_schedule
        end
      end
      resources :recurring_orders do
        collection do
          post :bulk_generate
        end
      end
      resources :restaurants
      resources :staffs
      resources :supplies do
        collection do
          get :by_location
        end
        member do
          get :stocks_by_location
        end
      end
      resources :supply_movements
      resources :supply_stocks do
        collection do
          get :by_location
        end
      end
      resources :own_locations
      resources :bulk_supply_movements, only: [:new, :create] do
        collection do
          get :get_stocks
        end
      end

      root to: "admin_users#index"
    end
  devise_for :admin_users, skip: [:registrations]
  as :admin_user do
    get 'admin_users/edit' => 'devise/registrations#edit', as: :edit_admin_user_registration
    patch 'admin_users' => 'devise/registrations#update', as: :admin_user_registration
    put 'admin_users' => 'devise/registrations#update'
    delete 'admin_users' => 'devise/registrations#destroy'
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: redirect('/admin')
end
