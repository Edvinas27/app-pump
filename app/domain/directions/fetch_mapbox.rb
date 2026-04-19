# frozen_string_literal: true

require "net/http"

class Directions::FetchMapbox
  include Interactor::Initializer

  initialize_with :params

  LAT_RANGE = -90.0..90.0
  LNG_RANGE = -180.0..180.0

  def run
    errors = validate_params
    return { success: false, errors: errors } if errors.any?

    token = ENV["MAPBOX_ACCESS_TOKEN"]
    return { success: false, errors: ["Mapbox access token is not configured"] } if token.blank?

    coords = coordinate_path
    url = "https://api.mapbox.com/directions/v5/mapbox/driving/#{coords}?geometries=geojson&overview=full&access_token=#{ERB::Util.url_encode(token)}"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    return { success: false, errors: [data["message"] || "Mapbox routing failed"] } if data["code"] != "Ok"

    { success: true, data: data }
  rescue JSON::ParserError => e
    { success: false, errors: ["Invalid response from Mapbox: #{e.message}"] }
  rescue StandardError => e
    { success: false, errors: ["Directions request failed: #{e.message}"] }
  end

  private

  def validate_params
    errors = []
    %i[start_lat start_lng end_lat end_lng].each do |key|
      errors << "Missing parameter: #{key}" if params[key].blank?
    end
    return errors if errors.any?

    %i[start_lat start_lng end_lat end_lng].each do |key|
      value = params[key].to_s
      errors << "Invalid number: #{key}" unless Float(value, exception: false)
    end
    return errors if errors.any?

    start_lat = params[:start_lat].to_f
    start_lng = params[:start_lng].to_f
    end_lat = params[:end_lat].to_f
    end_lng = params[:end_lng].to_f

    errors << "start_lat must be between -90 and 90" unless LAT_RANGE.cover?(start_lat)
    errors << "start_lng must be between -180 and 180" unless LNG_RANGE.cover?(start_lng)
    errors << "end_lat must be between -90 and 90" unless LAT_RANGE.cover?(end_lat)
    errors << "end_lng must be between -180 and 180" unless LNG_RANGE.cover?(end_lng)

    errors.concat(validate_optional_via) if errors.empty?

    errors
  end

  def validate_optional_via
    errors = []
    has_via_lat = params[:via_lat].present?
    has_via_lng = params[:via_lng].present?
    if has_via_lat ^ has_via_lng
      errors << "via_lat and via_lng must both be present when using a waypoint"
      return errors
    end
    return errors unless has_via_lat

    %i[via_lat via_lng].each do |key|
      value = params[key].to_s
      errors << "Invalid number: #{key}" unless Float(value, exception: false)
    end
    return errors if errors.any?

    via_lat = params[:via_lat].to_f
    via_lng = params[:via_lng].to_f

    errors << "via_lat must be between -90 and 90" unless LAT_RANGE.cover?(via_lat)
    errors << "via_lng must be between -180 and 180" unless LNG_RANGE.cover?(via_lng)

    errors
  end

  def coordinate_path
    parts = [lng_lat(params[:start_lng], params[:start_lat])]
    if params[:via_lat].present?
      parts << lng_lat(params[:via_lng], params[:via_lat])
    end
    parts << lng_lat(params[:end_lng], params[:end_lat])
    parts.join(";")
  end

  def lng_lat(lng, lat)
    "#{lng},#{lat}"
  end
end
