# frozen_string_literal: true

class CarsController < BaseController
  def get
    result = Cars::Get.for(car_params)

    render json: result, status: :ok
  end

  def create
    result = Cars::Create.for(car_params)

    if result[:success]
      render json: result[:car], status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def car_params
    params.permit(:brand_name, :model, :co2_emission, :fuel_type_id).to_h
  end
end
