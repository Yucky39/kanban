Cybertrain::Routes.draw do
  root "boards#index"

  resources :boards, only: [:index, :show, :create, :destroy] do |boards|
    boards.resources :cards, only: [:create]
  end
  resources :cards, only: [:destroy]
  patch "/cards/:id/left", to: "cards#move_left", as: "move_card_left"
  patch "/cards/:id/right", to: "cards#move_right", as: "move_card_right"

  get "/login", to: "sessions#new_action", as: "login"
  post "/login", to: "sessions#create", as: "create_session"
  delete "/logout", to: "sessions#destroy", as: "logout"
  get "/signup", to: "registrations#new_action", as: "signup"
  post "/signup", to: "registrations#create", as: "create_registration"
  get "/password/forgot", to: "password_resets#new_action", as: "forgot_password"
  post "/password/forgot", to: "password_resets#create", as: "create_forgot_password"
  get "/password/reset/:token", to: "password_resets#edit", as: "reset_password"
  post "/password/reset", to: "password_resets#update", as: "update_password"
  get "/email/resend", to: "email_verifications#new_action", as: "resend_verification"
  post "/email/resend", to: "email_verifications#create", as: "create_resend_verification"
  get "/email/verify/:token", to: "email_verifications#edit", as: "verify_email"
  post "/email/verify", to: "email_verifications#update", as: "update_verify_email"
  get "/account/email", to: "email_changes#new_action", as: "change_email"
  post "/account/email", to: "email_changes#create", as: "create_change_email"
  get "/email/change/:token", to: "email_changes#edit", as: "confirm_email_change"
  post "/email/change", to: "email_changes#update", as: "update_email_change"
  get "/email/revert/:token", to: "email_changes#revert_form", as: "revert_email_change_form"
  post "/email/revert", to: "email_changes#revert", as: "revert_email_change"
end
