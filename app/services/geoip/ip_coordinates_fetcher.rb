# frozen_string_literal: true

require "net/http"
require "json"

module Geoip
  # Fetches latitude/longitude for an IP using a free external API (ip-api.com).
  # Used to then call Mapbox reverse geocoding for country/city.
  class IpCoordinatesFetcher
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5
    BASE_URL = "http://ip-api.com/json"

    def initialize(base_url: nil)
      @base_url = (base_url || BASE_URL).chomp("/")
    end

    # Returns { latitude: Float, longitude: Float } or {} on failure.
    def fetch(ip)
      return {} if ip.blank?

      # Skip private/local IPs
      return {} if private_or_local?(ip)

      uri = URI("#{@base_url}/#{ERB::Util.url_encode(ip)}")
      response = get(uri)
      return {} unless response.is_a?(Net::HTTPSuccess)

      parse(response.body)
    rescue StandardError => e
      Rails.logger.warn("[Geoip::IpCoordinatesFetcher] fetch failed: #{e.message}")
      {}
    end

    private

    def private_or_local?(ip)
      return true if ip == "127.0.0.1" || ip == "::1" || ip.to_s.start_with?("192.168.") || ip.to_s.start_with?("10.")
      return true if ip.to_s.match?(/\A127\./)
      false
    end

    def get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.get(uri.request_uri)
      end
    end

    def parse(body)
      data = JSON.parse(body)
      lat = data["lat"]
      lon = data["lon"]
      return {} if lat.nil? || lon.nil?

      { latitude: lat.to_f, longitude: lon.to_f }
    rescue JSON::ParserError
      {}
    end
  end
end
