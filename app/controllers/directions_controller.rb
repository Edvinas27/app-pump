class DirectionsController < BaseController
  before_action :require_current_user!

  def show
    result = Directions::FetchMapbox.for(directions_params)

    return render json: { errors: result[:errors] }, status: :unprocessable_content unless result[:success]

    enriched = Directions::RouteDistance.enrich_mapbox_payload(result[:data])

    routes = apply_filters(enriched["routes"])

    render json: enriched.merge("routes" => routes), status: :ok
  end

  private

  def directions_params
    params.permit(:start_lat, :start_lng, :end_lat, :end_lng, :via_lat, :via_lng).to_h.symbolize_keys
  end

  def filter_params
    params.permit(:car_id, :max_co2_kg, :avoid_lez, :hide_exceeding)
  end

  def apply_filters(routes)
    car = current_user.cars.find_by(id: filter_params[:car_id])
    return routes unless car

    max_co2 = filter_params[:max_co2_kg]&.to_f
    avoid_lez = ActiveModel::Type::Boolean.new.cast(filter_params[:avoid_lez])
    hide = ActiveModel::Type::Boolean.new.cast(filter_params[:hide_exceeding])

    routes.map do |route|
      distance_km = route["distance_km"]

      co2_kg = calculate_co2(car, distance_km)
      passes_lez = detect_lez(route) # placeholder

      route.merge(
        "co2_kg" => co2_kg,
        "exceeds_co2" => max_co2.present? && co2_kg > max_co2,
        "passes_lez" => passes_lez
      )
    end
    .reject do |route|
      (hide && route["exceeds_co2"]) ||
      (avoid_lez && route["passes_lez"])
    end
  end

  def calculate_co2(car, distance_km)
    ((car.co2_emission.to_f * distance_km) / 1000).round(2)
  end

  def detect_lez(route) #zemos emisijos zona
    
    false
  end
end
