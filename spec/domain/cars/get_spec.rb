# frozen_string_literal: true

RSpec.describe Cars::Get do
  subject { described_class.for(params) }

  let!(:fuel_type) { create(:fuel_type) }
  let(:params) {
    {
      brand_name: "Audi",
      model: "A4",
      co2_emission: 120,
      fuel_type_id: fuel_type.id
    }
  }

  context 'when car exists' do
    let!(:car) { create(:car, **params) }

    it 'returns the car' do
      expect(subject).to be_present
      expect(subject).to be_a(Hash)
    end

    it 'returns the car with fuel type' do
      expect(subject).to eq({
        id: car.id,
        brand_name: car.brand_name,
        model: car.model,
        co2_emission: car.co2_emission,
        fuel_type: {
          id: fuel_type.id,
          name: fuel_type.name
        }})
    end
  end

  context 'when car does not exist' do
    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end
end
