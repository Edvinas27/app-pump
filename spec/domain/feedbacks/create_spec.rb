# frozen_string_literal: true

RSpec.describe Feedbacks::Create do
  subject { described_class.for(params) }

  let(:params) {
    {
      comment: "Great app!",
      rating: 5
    }
  }

  context 'when params are valid' do
    it 'creates a new feedback' do
      expect { subject }.to change(Feedback, :count).by(1)
      expect(subject[:success]).to be true
    end
  end

  context 'when params are invalid' do
    let(:params) { { comment: nil, rating: nil } }

    it 'does not create a new feedback' do
      expect { subject }.not_to change(Feedback, :count)
      expect(subject[:success]).to be false
    end

    it 'returns a hash of translated errors' do
      expect(subject[:errors]).to include(
        comment: "can't be blank",
        rating: "can't be blank"
      )
    end
  end
end

