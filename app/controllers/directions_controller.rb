# frozen_string_literal: true

class DirectionsController < BaseController
  def show
    result = Directions::FetchMapbox.for(directions_params)

    if result[:success]
      render json: result[:data], status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def directions_params
    params.permit(:start_lat, :start_lng, :end_lat, :end_lng).to_h.symbolize_keys
  end
end
