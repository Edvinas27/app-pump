class DirectionsController < BaseController
  before_action :require_current_user!

  def show
    result = Directions::FetchMapbox.for(directions_params)

    if result[:success]
      render json: Directions::RouteDistance.enrich_mapbox_payload(result[:data]), status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def directions_params
    params.permit(:start_lat, :start_lng, :end_lat, :end_lng, :via_lat, :via_lng).to_h.symbolize_keys
  end
end