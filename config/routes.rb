Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'trigger_happy#index'

  post '/top_five', to: 'trigger_happy#fetch_top_five'
end
