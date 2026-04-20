# frozen_string_literal: true

class Geoip::ResolveLocation
  include Interactor::Initializer

  initialize_with :ip

  EMPTY = { country: nil, city: nil, latitude: nil, longitude: nil }.freeze

  def run
    coords = Geoip::IpCoordinatesFetcher.new.fetch(ip)
    return EMPTY.dup if coords.blank?

    place = Geoip::MapboxClient.new.reverse_geocode(
      longitude: coords[:longitude],
      latitude: coords[:latitude]
    )

    {
      country: place[:country],
      city: place[:city],
      latitude: coords[:latitude],
      longitude: coords[:longitude]
    }
  end
end
