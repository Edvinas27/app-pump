# frozen_string_literal: true

require "net/http"
require "json"

module Geoip
  # Reverse-geocodes lat/lng into { country:, city: } via Mapbox Geocoding v6.
  # Returns nils (not raises) on any failure so callers can keep flowing (login must not fail).
  class MapboxClient
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5

    EMPTY_PLACE = { country: nil, city: nil }.freeze

    def initialize(access_token: nil, base_url: nil)
      @access_token = access_token || Rails.application.config.x.mapbox_access_token
      @base_url = (base_url || Rails.application.config.x.mapbox_geocode_url).to_s.chomp("/")
    end

    # Returns { country: String|nil, city: String|nil }. Never raises.
    def reverse_geocode(longitude:, latitude:)
      return EMPTY_PLACE.dup if @access_token.blank?

      uri = URI("#{@base_url}/reverse")
      uri.query = URI.encode_www_form(
        longitude: longitude,
        latitude: latitude,
        access_token: @access_token
      )

      response = get(uri)
      return EMPTY_PLACE.dup unless response.is_a?(Net::HTTPSuccess)

      parse_reverse_response(response.body)
    rescue StandardError => e
      Rails.logger.warn("[Geoip::MapboxClient] reverse_geocode failed: #{e.message}")
      EMPTY_PLACE.dup
    end

    private

    def get(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      ) do |http|
        http.get(uri.request_uri)
      end
    end

    def parse_reverse_response(body)
      data = JSON.parse(body)
      features = data["features"]
      return EMPTY_PLACE.dup if features.blank?

      props = features.first["properties"] || {}
      context = props["context"] || {}
      country = context.dig("country", "name")
      city = context.dig("place", "name")

      { country: country.presence, city: city.presence }
    rescue JSON::ParserError
      EMPTY_PLACE.dup
    end
  end
end
