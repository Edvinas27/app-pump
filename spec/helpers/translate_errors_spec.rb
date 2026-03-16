# frozen_string_literal: true

RSpec.describe TranslateErrors do
  subject { described_class.for(instance) }

  let(:instance) { build(:car, brand_name: brand_name, co2_emission: co2_emission) }
  let(:brand_name) { "Audi" }
  let(:co2_emission) { 100 }

  context 'when instance has no errors' do
    it 'returns an empty hash' do
      instance.valid?
      expect(subject).to eq({})
    end
  end

  context 'when instance has one error' do
    let(:brand_name) { nil }

    it 'returns a hash of formated error messages' do
      instance.valid?
      expect(subject).to eq({ brand_name: "can't be blank" })
    end
  end

  context 'when instance has multiple errors' do
    let(:brand_name) { nil }
    let(:co2_emission) { -1 }

    it 'returns a hash of formated error messages' do
      instance.valid?
      expect(subject).to eq({ brand_name: "can't be blank",
                              co2_emission: "must be greater than or equal to 0" })
    end
  end
end
