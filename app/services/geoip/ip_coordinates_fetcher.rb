# frozen_string_literal: true

require "net/http"
require "json"
require "ipaddr"

module Geoip
  # Fetches latitude/longitude for a public IP using ip-api.com (no key required).
  # Private / loopback / non-public IPs are short-circuited without making any HTTP call.
  class IpCoordinatesFetcher
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5
    BASE_URL = "http://ip-api.com/json"

    def initialize(base_url: nil)
      @base_url = (base_url || BASE_URL).chomp("/")
    end

    # Returns { latitude: Float, longitude: Float } or {} on failure / non-public IP.
    def fetch(ip)
      return {} if ip.blank?
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
      addr = IPAddr.new(ip.to_s)
      addr.loopback? || addr.private? || addr.link_local?
    rescue IPAddr::InvalidAddressError
      true
    end

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
