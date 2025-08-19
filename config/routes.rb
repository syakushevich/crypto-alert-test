Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :alerts
      resources :notification_channels
    end
  end
end
