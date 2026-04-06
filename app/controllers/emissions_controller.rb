# frozen_string_literal: true

class EmissionsController < BaseController
  before_action :require_current_user!

  def calculate
    return render json: { error: "car_id is required" }, status: :unprocessable_content if params[:car_id].blank?

    car = current_user.cars.find_by(id: params[:car_id])
    return render json: { error: "Car not found" }, status: :not_found if car.nil?

    result = Emissions::Calculate.for(car, params[:distance_km])

    render json: result, status: :ok
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  end
end

