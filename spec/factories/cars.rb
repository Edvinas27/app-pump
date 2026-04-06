# frozen_string_literal: true

FactoryBot.define do
  factory :car do
    brand_name { "Tesla" }
    model { "Model S" }
    year { 2024 }
    co2_emission { 0 }
    fuel_type
  end
end