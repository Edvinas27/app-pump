# frozen_string_literal: true

class Car < MainModel
  belongs_to :fuel_type

  validates :brand_name, :model, :fuel_type, :co2_emission, presence: true

  validates :brand_name, uniqueness: {
    scope: [ :model, :fuel_type_id, :co2_emission ],
    message: "A car with this brand, model, fuel type, and emission already exists."
  }
end
