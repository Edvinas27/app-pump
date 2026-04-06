# frozen_string_literal: true

RSpec.describe Cars::Create do
  subject { described_class.for(params) }

  let!(:fuel_type) { create(:fuel_type) }
  let(:params) {
    {
      brand_name: "Audi",
      model: "A4",
      year: 2022,
      co2_emission: 120,
      fuel_type_id: fuel_type.id
    }
  }

  context 'when params are valid' do
    it 'creates a new car' do
      expect { subject }.to change(Car, :count).by(1)
      expect(subject[:success]).to be true
    end
  end

  context 'when params are invalid' do
    let(:params) { { brand_name: nil, model: nil, year: nil, co2_emission: -1, fuel_type_id: nil } }

    it 'does not create a new car' do
      expect { subject }.not_to change(Car, :count)
      expect(subject[:success]).to be false
    end

    it 'returns a hash of translated errors' do
      expect(subject[:errors]).to eq({
        brand_name: "can't be blank",
        model: "can't be blank",
        year: "can't be blank",
        co2_emission: "must be greater than or equal to 0",
        fuel_type: "must exist"
      })
    end
  end

end