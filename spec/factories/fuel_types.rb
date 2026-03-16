# frozen_string_literal: true

FactoryBot.define do
  factory :fuel_type do
    sequence(:name) { |n| "Fuel #{n}" }
  end
end