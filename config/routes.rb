Rails.application.routes.draw do
  %w[live ready up].each do |path|
    get path, to: ->(_) { [200, {}, ["OK"]] }
  end

  post "users", to: "registrations#create"
  post "sessions", to: "sessions#create"

  get "me/cars", to: "user_cars#get"
  post "me/cars", to: "user_cars#create"

  post "cars", to: "cars#create"
  get "cars", to: "cars#get"

  post "feedbacks", to: "feedbacks#create"
  get "feedbacks", to: "feedbacks#get"

  get "directions", to: "directions#show"
end
