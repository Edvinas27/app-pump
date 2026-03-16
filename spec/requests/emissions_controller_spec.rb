# frozen_string_literal: true

RSpec.describe EmissionsController, type: :request do
  let(:fuel_type) { create(:fuel_type) }
  let(:car) { create(:car, fuel_type: fuel_type, co2_emission: 120) }

  describe 'POST /emissions/calculate' do
    context 'when car is selected and distance is valid' do
      it 'returns calculated emissions with status 200' do
        post '/emissions/calculate', params: { car_id: car.id, distance_km: 10 }

        expect(response).to have_http_status(:ok)
        expect(json_response['total_emission_g']).to eq(1200.0)
        expect(json_response['total_emission_kg']).to eq(1.2)
      end
    end

    context 'when car is not selected' do
      it 'returns an error with status 422' do
        post '/emissions/calculate', params: { car_id: nil, distance_km: 10 }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Car must be selected')
      end
    end

    context 'when distance is invalid' do
      it 'returns an error with status 422' do
        post '/emissions/calculate', params: { car_id: car.id, distance_km: 0 }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('Distance must be greater than 0')
      end
    end
  end
end

