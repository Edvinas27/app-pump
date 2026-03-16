# frozen_string_literal: true

require "net/http"
require "json"

module Geoip
  class MapboxClient
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5

    def initialize(access_token: nil, base_url: nil)
      @access_token = access_token || Rails.application.config.x.mapbox_access_token
      @base_url = (base_url || Rails.application.config.x.mapbox_geocode_url).chomp("/")
    end

    # Returns { country: String|nil, city: String|nil } from Mapbox reverse geocoding.
    # Returns nils on any error or missing token; logs and does not raise.
    def reverse_geocode(longitude:, latitude:)
      return { country: nil, city: nil } if @access_token.blank?

      uri = URI("#{@base_url}/reverse")
      uri.query = URI.encode_www_form(
        longitude: longitude,
        latitude: latitude,
        access_token: @access_token
      )

      response = get(uri)
      return { country: nil, city: nil } unless response.is_a?(Net::HTTPSuccess)

      parse_reverse_response(response.body)
    rescue StandardError => e
      Rails.logger.warn("[Geoip::MapboxClient] reverse_geocode failed: #{e.message}")
      { country: nil, city: nil }
    end

    private

    def get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.get(uri.request_uri)
      end
    end

    def parse_reverse_response(body)
      data = JSON.parse(body)
      features = data["features"]
      return { country: nil, city: nil } if features.blank?

      # First feature is most specific (e.g. address); context has country, place (city)
      props = features.first["properties"] || {}
      context = props["context"] || {}
      country = context.dig("country", "name")
      city = context.dig("place", "name")

      { country: country.presence, city: city.presence }
    rescue JSON::ParserError
      { country: nil, city: nil }
    end
  end
end
