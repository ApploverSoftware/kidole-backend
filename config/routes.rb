Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :users, only: %i[create show index]
      resource :auth_token, only: %i[create destroy]
    end
  end
end
