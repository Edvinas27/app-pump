# frozen_string_literal: true

RSpec.describe FeedbacksController, type: :request do
  let(:valid_attributes) do
    {
      comment: "Great app!",
      rating: 5
    }
  end

  describe 'GET' do
    before do
      create_list(:feedback, 3)
    end

    it 'returns all feedbacks with status 200' do
      get '/feedbacks'

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(3)
    end
  end

  describe 'POST' do
    context 'with valid parameters' do
      it 'creates a new Feedback and returns 201' do
        expect {
          post '/feedbacks', params: valid_attributes
        }.to change(Feedback, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['comment']).to eq('Great app!')
      end
    end

    context 'with invalid parameters' do
      it 'returns errors with status 422' do
        post '/feedbacks', params: { comment: nil, rating: nil }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to have_key('comment')
        expect(json_response['errors']).to have_key('rating')
      end
    end
  end
end

