# frozen_string_literal: true

class Geoip::ResolveLocation
  include Interactor::Initializer

  initialize_with :ip

  def run
    ip_str = ip.is_a?(Hash) ? ip[:ip] : ip
    coords = Geoip::IpCoordinatesFetcher.new.fetch(ip_str)
    return { country: nil, city: nil } if coords.blank?

    Geoip::MapboxClient.new.reverse_geocode(
      longitude: coords[:longitude],
      latitude: coords[:latitude]
    )
  end
end
