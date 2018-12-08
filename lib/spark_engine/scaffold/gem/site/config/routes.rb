Rails.application.routes.draw do
  get '*path', to: 'docs#show'
  resources :docs, param: :page, path: ''
end
