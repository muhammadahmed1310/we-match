Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"

  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  get "guide", to: "pages#flow", as: :flow_guide

  # Participant flow. Authenticated by the invitation token in the URL, so these
  # are the only non-API routes that do not require an admin session.
  get "respond/:token", to: "participant_responses#edit", as: :participant_response
  patch "respond/:token", to: "participant_responses#update"
  get "respond/:token/thank-you", to: "participant_responses#show", as: :participant_response_confirmation

  resource :import, only: %i[new create], controller: "imports"

  resources :groups do
    member do
      patch :toggle_auto_cycle
    end
  end

  resources :members

  resources :topics do
    resources :topic_options, only: %i[new create edit update destroy]
  end

  resources :match_cycles, except: %i[destroy] do
    member do
      post :send_invitations
      post :close
      post :run_matching
      get :invitations
    end

    resources :match_responses, only: %i[new create edit update]
    resources :matches, only: %i[index]
  end

  get "reports", to: "reports#index", as: :reports
  get "reports/cycles/:id", to: "reports#cycle", as: :cycle_report

  namespace :api do
    namespace :v1 do
      resources :groups, only: [ :index ]
      resources :members, only: [ :index ]
      resources :topics, only: [ :index ]

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
