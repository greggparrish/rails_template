Rails.application.routes.draw do
  devise_for :users, :controllers => { registrations: 'registrations' }, path: "/", path_names: { 
    sign_in: 'login', 
    sign_out: 'logout', 
    password: 'secret', 
    confirmation: 'verification', 
    unlock: 'unblock', 
    registration: 'register', 
    sign_up: 'sign_up' 
  }

  #Static pages
  root "static_pages#home"
  get "contact" => "static_pages#contact" 
  get "about" => "static_pages#about" 

end
