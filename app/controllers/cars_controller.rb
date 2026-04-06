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

  def brands
    render json: Car.distinct.order(:brand_name).pluck(:brand_name), status: :ok
  end

  def models
    return render json: { error: "brand_name is required" }, status: :unprocessable_content if params[:brand_name].blank?

    models = Car.where(brand_name: params[:brand_name]).distinct.order(:model).pluck(:model)
    render json: models, status: :ok
  end

  def fuel_types
    if params[:brand_name].blank? || params[:model].blank?
      return render json: { error: "brand_name and model are required" }, status: :unprocessable_content
    end

    fuel_types = FuelType.joins(:cars)
                         .where(cars: { brand_name: params[:brand_name], model: params[:model] })
                         .distinct
                         .order(:name)
                         .pluck(:id, :name)
                         .map { |id, name| { id: id, name: name } }

    render json: fuel_types, status: :ok
  end

  def years
    if params[:brand_name].blank? || params[:model].blank? || params[:fuel_type_id].blank?
      return render json: { error: "brand_name, model and fuel_type_id are required" }, status: :unprocessable_content
    end

    years = Car.where(
      brand_name: params[:brand_name],
      model: params[:model],
      fuel_type_id: params[:fuel_type_id]
    ).distinct.order(:year).pluck(:year)

    render json: years, status: :ok
  end

  private

  def car_params
    params.permit(:brand_name, :model, :co2_emission, :fuel_type_id, :year).to_h
  end
end
