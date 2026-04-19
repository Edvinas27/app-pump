# frozen_string_literal: true

class GeocodingController < BaseController
  before_action :require_current_user!

  def reverse
    result = ::Geocoding::ReverseMapbox.for(geocode_params)

    if result[:success]
      render json: { label: result[:label] }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def geocode_params
    params.permit(:lat, :lng).to_h.symbolize_keys
  end
end
