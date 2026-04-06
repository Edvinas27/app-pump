# frozen_string_literal: true

RSpec.describe EmissionsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:fuel_type) { create(:fuel_type) }
  let(:car) { create(:car, fuel_type: fuel_type, co2_emission: 120) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe 'POST /emissions/calculate' do
    context 'when car is selected and distance is valid' do
      it 'returns calculated emissions with status 200' do
        create(:user_car, user: user, car: car)
        post '/emissions/calculate', params: { car_id: car.id, distance_km: 10 }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['total_emission_g']).to eq(1200.0)
        expect(json_response['total_emission_kg']).to eq(1.2)
      end
    end

    context 'when car_id is not provided' do
      it 'returns an error with status 422' do
        post '/emissions/calculate', params: { car_id: nil, distance_km: 10 }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('car_id is required')
      end
    end

    context 'when car does not exist' do
      it 'returns an error with status 404' do
        post '/emissions/calculate', params: { car_id: 999_999, distance_km: 10 }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Car not found')
      end
    end

    context 'when car is not assigned to current user' do
      it 'returns an error with status 404' do
        create(:user_car, user: other_user, car: car)

        post '/emissions/calculate', params: { car_id: car.id, distance_km: 10 }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Car not found')
      end
    end

    context 'when distance is invalid' do
      it 'returns an error with status 422' do
        create(:user_car, user: user, car: car)
        post '/emissions/calculate', params: { car_id: car.id, distance_km: 0 }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Distance must be greater than 0')
      end
    end

    context 'when distance is not numeric' do
      it 'returns an error with status 422' do
        create(:user_car, user: user, car: car)
        post '/emissions/calculate', params: { car_id: car.id, distance_km: '10km' }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Distance must be a valid number')
      end
    end

    context 'when auth header is missing' do
      it 'returns 401 unauthorized' do
        post '/emissions/calculate', params: { car_id: car.id, distance_km: 10 }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end

