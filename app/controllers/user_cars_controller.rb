# frozen_string_literal: true

class UserCarsController < BaseController
  before_action :require_current_user!

  def create
    user_car = UserCar.new(car_id: user_car_params[:car_id], user: current_user)

    if user_car.save
      render json: format_car(user_car.car), status: :created
    else
      render json: { errors: TranslateErrors.for(user_car) }, status: :unprocessable_content
    end
  end

  def get
    result = current_user.cars.includes(:fuel_type).map { |car| format_car(car) }
    render json: result, status: :ok
  end

  private

  def user_car_params
    params.permit(:car_id).to_h
  end

  def format_car(car)
    {
      id: car.id,
      brand_name: car.brand_name,
      model: car.model,
      year: car.year,
      co2_emission: car.co2_emission,
      fuel_type: {
        id: car.fuel_type.id,
        name: car.fuel_type.name
      }
    }
  end
end
