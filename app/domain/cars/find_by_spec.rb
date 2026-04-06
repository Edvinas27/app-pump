#pvz Cars::FindBySpec.for(brand_name: "FORD", model: "PUMA")
class Cars::FindBySpec
  include Interactor::Initializer
  initialize_with :params

  def run
    car = Car.includes(:fuel_type)
             .find_by(brand_name: params[:brand_name],
                      model: params[:model])

    if car
      format_car(car)
    else
      { error: "Car not found" }
    end
  end

  private

  def format_car(car)
    {
      id: car.id,
      brand_name: car.brand_name,
      model: car.model,
      co2_emission: car.co2_emission,
      fuel_type: car.fuel_type&.name
    }
  end
end