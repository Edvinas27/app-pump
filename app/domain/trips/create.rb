class Trips::Create
  include Interactor::Initializer

  initialize_with :user_id, :user_car_id, :route_id

  def run
    user_car = UserCar.find_by!(id: user_car_id, user_id: user_id)
    route = Route.find(route_id)

    car = user_car.car

    result = Emissions::Calculate.new(car, route.total_length).run

    Trip.create!(
      user_car: user_car,
      route: route,
      distance_km: route.total_length,
      co2_emission_kg: result[:total_emission_kg]
    )
  end
end