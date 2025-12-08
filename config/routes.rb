Rails.application.routes.draw do
  namespace :admin do
      resources :admin_users
      resources :companies
      resources :delivery_companies
      resources :delivery_sheet_items
      resources :drivers
      resources :delivery_users
      resources :delivery_assignments do
        collection do
          post :bulk_assign
        end
      end
      resources :menus
      resources :orders do
        collection do
          get :calendar
          get :schedule
          patch :update_schedule
          get :delivery_sheets
          get :delivery_sheet_pdf
        end
      end
      resources :recurring_orders do
        collection do
          post :bulk_generate
        end
        member do
          get :generate_weekly
          post :create_weekly_orders
        end
      end
      resources :invoices
      resources :invoice_items
      resources :payments
      resources :invoice_pdfs, only: [:show]
      resources :invoice_generations, only: [:create]
      resources :reports, only: [:index] do
        collection do
          get :chart_data
          get :export_pdf
          get :export_csv
        end
      end
      resources :restaurants
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
      resources :supply_inventories, only: [:index, :new, :create, :show]
      resources :supply_forecasts, only: [:index, :show]
      resources :delivery_plans do
        collection do
          post :auto_generate
        end
        member do
          post :add_orders
          patch :reorder_items
        end
        resources :delivery_plan_items, only: [:new, :create, :edit, :update, :destroy]
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

  # Delivery users authentication
  devise_for :delivery_users, path: 'delivery', skip: [:registrations], controllers: {
    sessions: 'delivery/sessions',
    passwords: 'delivery/passwords'
  }

  # Delivery namespace
  namespace :delivery do
    root to: 'dashboard#index'
    resources :assignments, only: [:index, :show] do
      member do
        patch :update_status
      end
      resource :report, only: [:new, :create]
    end
    resources :reports, only: [:show]
    resources :histories, only: [:index]
    resource :profile, only: [:show, :edit, :update]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: redirect('/admin')
end
