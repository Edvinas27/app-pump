Rails.application.routes.draw do
  %w[live ready up].each do |path|
    get path, to: ->(_) { [200, {}, ["OK"]] }
  end

  post "users", to: "registrations#create"
  post "sessions", to: "sessions#create"

  get "me/cars", to: "user_cars#get"
  post "me/cars", to: "user_cars#create"
  delete "me/cars/:car_id", to: "user_cars#destroy"

  post "cars", to: "cars#create"
  get "cars", to: "cars#get"
  get "cars/brands", to: "cars#brands"
  get "cars/models", to: "cars#models"
  get "cars/fuel_types", to: "cars#fuel_types"
  get "cars/years", to: "cars#years"
  post "feedbacks", to: "feedbacks#create"
  get "feedbacks", to: "feedbacks#get"

  get "directions", to: "directions#show"
  get "geocode/reverse", to: "geocoding#reverse"
  post "emissions/calculate", to: "emissions#calculate"
end
