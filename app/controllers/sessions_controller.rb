# frozen_string_literal: true

class SessionsController < BaseController
  # After successful login: resolve location by IP and keep country/city in memory (no DB).
  # Call this from your real auth flow, then use the local variables or session as needed.
  def create
    location = Geoip::ResolveLocation.for(ip: request.remote_ip)
    country = location[:country]
    city = location[:city]

    render json: { country: country, city: city, login_ip: request.remote_ip }, status: :created
  end

  # POST /session/lookup – same response shape, but you can send an IP in the body for testing.
  # Body (JSON): { "ip": "8.8.8.8" }. If "ip" is missing, uses request.remote_ip.
  def lookup
    ip = params[:ip].presence || request.remote_ip
    location = Geoip::ResolveLocation.for(ip: ip)
    render json: { country: location[:country], city: location[:city], login_ip: ip }, status: :ok
  end
end
