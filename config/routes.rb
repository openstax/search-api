Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    api_version(
      module: 'V0',
      path: { value: 'v0' },
      defaults: { format: :json },
      default: true
    ) do

      get :swagger, to: 'swagger/docs#json'

      get :prototype, to: 'prototype#search'
      get :temp_build_index, to: 'prototype#temp_build_index'

      get :search, to: 'search#search'

      resources :diagnostics, only: [] do
        get :exception, on: :collection
      end
    end
  end
end
