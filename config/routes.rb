Rails.application.routes.draw do
  %w[live ready up].each do |path|
    get path, to: ->(_) { [200, {}, ["OK"]] }
  end

  post "cars", to: "cars#create"
  get "cars", to: "cars#get"
  get "cars/brands", to: "cars#brands"
  get "cars/models", to: "cars#models"
  get "cars/fuel_types", to: "cars#fuel_types"
  get "cars/years", to: "cars#years"

  post "me/cars", to: "user_cars#create"
  get "me/cars", to: "user_cars#get"

  post "users", to: "registrations#create"
  post "sessions", to: "sessions#create"
  post "feedbacks", to: "feedbacks#create"
  get "feedbacks", to: "feedbacks#get"

  get "directions", to: "directions#show"
  post "emissions/calculate", to: "emissions#calculate"
end
