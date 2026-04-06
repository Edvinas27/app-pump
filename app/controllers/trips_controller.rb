class TripsController < ApplicationController
  def create
    route = Route.find(params[:route_id])
    user_car = current_user.user_cars.find(params[:user_car_id])

    result = Emissions::Calculate.new(user_car.car, route.total_length).run

    trip = Trip.create!(
      user_car: user_car,
      route: route,
      distance_km: route.total_length,
      co2_emission_kg: result[:total_emission_kg]
    )

    render json: trip
  end

  def history
    render json: Trips::History.new(current_user.id).run
  end
end