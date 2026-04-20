# frozen_string_literal: true

require "net/http"

class Geocoding::ReverseMapbox
  include Interactor::Initializer

  initialize_with :params

  LAT_RANGE = -90.0..90.0
  LNG_RANGE = -180.0..180.0

  def run
    errors = validate_params
    return { success: false, errors: errors } if errors.any?

    token = ENV["MAPBOX_ACCESS_TOKEN"]
    return { success: false, errors: ["Mapbox access token is not configured"] } if token.blank?

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    url = "https://api.mapbox.com/geocoding/v5/mapbox.places/#{lng},#{lat}.json?limit=1&access_token=#{ERB::Util.url_encode(token)}"
    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    if data["message"].present? && data["features"].blank?
      return { success: false, errors: [data["message"]] }
    end

    label = data.dig("features", 0, "place_name")
    { success: true, label: label }
  rescue JSON::ParserError => e
    { success: false, errors: ["Invalid response from Mapbox: #{e.message}"] }
  rescue StandardError => e
    { success: false, errors: ["Geocoding request failed: #{e.message}"] }
  end

  private

  def validate_params
    errors = []
    %i[lat lng].each do |key|
      errors << "Missing parameter: #{key}" if params[key].blank?
    end
    return errors if errors.any?

    %i[lat lng].each do |key|
      errors << "Invalid number: #{key}" unless Float(params[key].to_s, exception: false)
    end
    return errors if errors.any?

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    errors << "lat must be between -90 and 90" unless LAT_RANGE.cover?(lat)
    errors << "lng must be between -180 and 180" unless LNG_RANGE.cover?(lng)

    errors
  end
end
