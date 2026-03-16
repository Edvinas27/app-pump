# frozen_string_literal: true

class EmissionsController < BaseController
  def calculate
    car = Car.find_by(id: params[:car_id])

    if car.nil?
      render json: { error: "Car must be selected" }, status: :unprocessable_content
      return
    end

    result = Emissions::Calculate.for(car, params[:distance_km])

    render json: result, status: :ok
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  end
end

