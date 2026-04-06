class Trips::History
  include Interactor::Initializer

  initialize_with :user_id

  def run
    trips = Trip.includes(user_car: :car, route: [:end_location])
                .joins(:user_car)
                .where(user_cars: { user_id: user_id })

    trips.map do |trip|
      car = trip.user_car.car
      route = trip.route

      {
        date: trip.created_at,
        car: "#{car.brand_name} #{car.model}",
        distance_km: trip.distance_km,
        co2_emission_kg: trip.co2_emission_kg,
        destination: route.end_location.address
      }
    end
  end
end