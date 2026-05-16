Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"

  get "guide", to: "pages#flow", as: :flow_guide

  resources :groups, only: [ :index, :show ]
  resources :members, only: [ :index, :show ]

  resources :match_cycles, only: [ :index, :show, :new, :create ] do
    member do
      post :send_invitations
      post :run_matching
    end

    resources :match_responses, only: [ :new, :create, :edit, :update ]
    resources :matches, only: [ :index ]
  end

  namespace :api do
    namespace :v1 do
      resources :groups, only: [ :index ]
      resources :members, only: [ :index ]

      resources :match_cycles, only: [ :show ] do
        member do
          post :run_matching
        end

        resources :match_responses, only: [ :create, :update ]
        resources :matches, only: [ :index ]
      end
    end
  end
end
