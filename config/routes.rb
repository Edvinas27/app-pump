Rails.application.routes.draw do
  %w[live ready up].each do |path|
    get path, to: ->(_) { [200, {}, ["OK"]] }
  end

  post "cars", to: "cars#create"
  get "cars", to: "cars#get"

  post "users", to: "registrations#create"
end
