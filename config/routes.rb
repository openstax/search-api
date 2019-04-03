Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    api_version(
      module: 'V0',
      path: { value: 'v0' },
      defaults: { format: :json },
      default: true
    ) do

      get :search, to: 'search#search'

      get :temp_build_index, to: 'search#temp_build_index'

    end
  end

end
