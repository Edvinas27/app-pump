# frozen_string_literal: true

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

    coords = "#{params[:start_lng]},#{params[:start_lat]};#{params[:end_lng]},#{params[:end_lat]}"
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

    errors
  end
end
