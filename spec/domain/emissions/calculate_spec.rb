# frozen_string_literal: true

RSpec.describe Emissions::Calculate do
  subject { described_class.for(car, distance_km) }

  let(:car) { build(:car, co2_emission: 120) } # 120 g/km
  let(:distance_km) { 10 } # 10 km

  context 'when car is selected and distance is valid' do
    it 'calculates total CO2 emission in grams and kilograms' do
      result = subject

      expect(result[:distance_km]).to eq(10.0)
      expect(result[:emission_rate_g_per_km]).to eq(120.0)
      expect(result[:total_emission_g]).to eq(1200.0)
      expect(result[:total_emission_kg]).to eq(1.2)
    end
  end

  context 'when car is not selected' do
    let(:car) { nil }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError, "Car must be selected")
    end
  end

  context 'when distance is zero or negative' do
    let(:distance_km) { 0 }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError, "Distance must be greater than 0")
    end
  end

  context 'when distance is not numeric' do
    let(:distance_km) { "10km" }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError, "Distance must be a valid number")
    end
  end

  context 'when distance is missing' do
    let(:distance_km) { nil }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError, "Distance must be a valid number")
    end
  end
end

