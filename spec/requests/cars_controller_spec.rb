RSpec.describe CarsController, type: :request do

  let(:fuel_type) { create(:fuel_type) }
  let(:valid_attributes) do
    {
      brand_name: 'Audi',
      model: 'A4',
      year: 2022,
      co2_emission: 120,
      fuel_type_id: fuel_type.id
    }
  end

  describe 'GET' do
    context 'when the car exists' do
      let!(:car) { create(:car, **valid_attributes) }

      it 'returns the car data with status 200' do
        get '/cars', params: valid_attributes

        expect(response).to have_http_status(:ok)
        expect(json_response['brand_name']).to eq('Audi')
      end
    end

    context 'when the car does not exist' do
      it 'returns an empty array with status 200' do
        get '/cars', params: { brand_name: '' }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end
    end
  end

  describe 'POST' do
    context 'with valid parameters' do
      it 'creates a new Car and returns 201' do
        expect {
          post '/cars', params: valid_attributes
        }.to change(Car, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['brand_name']).to eq('Audi')
      end
    end

    context 'with invalid parameters' do
      it 'returns errors with status 422' do
        post '/cars', params: { brand_name: nil }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to have_key('brand_name')
      end
    end
  end
end
