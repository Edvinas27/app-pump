# frozen_string_literal: true

RSpec.describe Feedbacks::Get do
  subject { described_class.for(params) }

  let(:params) { {} }

  context 'when feedbacks exist' do
    before do
      create_list(:feedback, 3)
    end

    it 'returns all feedbacks' do
      result = subject

      expect(result).to be_present
      expect(result.count).to eq(3)
    end
  end

  context 'when no feedbacks exist' do
    it 'returns an empty collection' do
      expect(subject).to be_empty
    end
  end
end

