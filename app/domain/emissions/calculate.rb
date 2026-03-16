# frozen_string_literal: true

class Emissions::Calculate
  include Interactor::Initializer

  initialize_with :car, :distance_km

  def run
    raise ArgumentError, "Car must be selected" if car.nil?

    distance = distance_km.to_f
    raise ArgumentError, "Distance must be greater than 0" if distance <= 0

    emission_rate_g_per_km = car.co2_emission.to_f
    total_emission_g = distance * emission_rate_g_per_km
    total_emission_kg = total_emission_g / 1000.0

    {
      distance_km: distance,
      emission_rate_g_per_km: emission_rate_g_per_km,
      total_emission_g: total_emission_g,
      total_emission_kg: total_emission_kg
    }
  end
end

