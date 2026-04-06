# frozen_string_literal: true

class Cars::Get
  include Interactor::Initializer

  initialize_with :params

  def run
    result = Car.includes(:fuel_type).find_by(params)

    result ? format_response(result) : []
  end

  private

  def format_response(car)
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
