Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'trigger_happy#index'

  post '/org',                   to: 'trigger_happy#create_org_tree'
  post '/contributions_history', to: 'trigger_happy#get_contributions_history'
end
