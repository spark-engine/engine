Rails.application.routes.draw do
  resources :docs, param: :page, path: ''
end
