Rails.application.routes.draw do
  %w[live ready up].each do |path|
    get path, to: ->(_) { [200, {}, ["OK"]] }
  end

  post "cars", to: "cars#create"
  get "cars", to: "cars#get"

  # After successful login: resolve location by IP; country/city returned in response (no DB).
  post "session", to: "sessions#create"
  # Optional: resolve location for a given IP (e.g. body: {"ip": "8.8.8.8"}) for testing from Postman.
  post "session/lookup", to: "sessions#lookup"
end
