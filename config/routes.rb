Rails.application.routes.draw do
  get "live", "ready", "up", to: ->(_) { [200, {}, ["OK"]] }
end
