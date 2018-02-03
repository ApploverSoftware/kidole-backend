# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :users, only: %i[create show] do
      end
      resource :auth_token, only: %i[create destroy]
      resources :chain_assets, only: %i[create] do
        post :issue, on: :collection
      end
    end
  end
end
