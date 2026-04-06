# frozen_string_literal: true

class Car < MainModel
  belongs_to :fuel_type

  validates :brand_name, :model, :fuel_type, :co2_emission, :year, presence: true
  validates :co2_emission, numericality: { greater_than_or_equal_to: 0 }
  validates :year, numericality: { only_integer: true, greater_than_or_equal_to: 1886 }

  validates :brand_name, uniqueness: {
    scope: [ :model, :fuel_type_id, :co2_emission, :year ],
    message: "a car with this brand, model, fuel type, emission, and year already exists."
  }
end
