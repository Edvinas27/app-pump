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

  describe 'GET /cars/brands' do
    before do
      create(:car, brand_name: "SpecBrandA", model: "One", year: 2022, co2_emission: 110, fuel_type: fuel_type)
      create(:car, brand_name: "SpecBrandB", model: "Two", year: 2023, co2_emission: 130, fuel_type: fuel_type)
    end

    it 'returns all distinct brand names' do
      get '/cars/brands'

      expect(response).to have_http_status(:ok)
      expect(json_response).to include("SpecBrandA", "SpecBrandB")
    end
  end

  describe 'GET /cars/models' do
    before do
      create(:car, brand_name: "SpecBrandModels", model: "SpecModelOne", year: 2022, co2_emission: 111, fuel_type: fuel_type)
      create(:car, brand_name: "SpecBrandModels", model: "SpecModelTwo", year: 2023, co2_emission: 112, fuel_type: fuel_type)
    end

    it 'returns models for selected brand' do
      get '/cars/models', params: { brand_name: 'SpecBrandModels' }

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(%w[SpecModelOne SpecModelTwo])
    end

    it 'returns 422 when brand_name is missing' do
      get '/cars/models'

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('brand_name is required')
    end
  end

  describe 'GET /cars/fuel_types' do
    let(:petrol_type) { create(:fuel_type, name: "SpecPetrol") }
    let(:diesel_type) { create(:fuel_type, name: "SpecDiesel") }

    before do
      create(:car, brand_name: "SpecBrandFuel", model: "SpecModelFuel", year: 2022, co2_emission: 140, fuel_type: petrol_type)
      create(:car, brand_name: "SpecBrandFuel", model: "SpecModelFuel", year: 2023, co2_emission: 141, fuel_type: diesel_type)
    end

    it 'returns fuel types for selected brand and model' do
      get '/cars/fuel_types', params: { brand_name: 'SpecBrandFuel', model: 'SpecModelFuel' }

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(
        [
          { 'id' => diesel_type.id, 'name' => 'SpecDiesel' },
          { 'id' => petrol_type.id, 'name' => 'SpecPetrol' }
        ]
      )
    end

    it 'returns 422 when required params are missing' do
      get '/cars/fuel_types', params: { brand_name: 'SpecBrandFuel' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('brand_name and model are required')
    end
  end

  describe 'GET /cars/years' do
    let(:years_fuel_type) { create(:fuel_type, name: "SpecYearFuel") }

    before do
      create(:car, brand_name: "SpecBrandYears", model: "SpecModelYears", year: 2020, co2_emission: 150, fuel_type: years_fuel_type)
      create(:car, brand_name: "SpecBrandYears", model: "SpecModelYears", year: 2021, co2_emission: 151, fuel_type: years_fuel_type)
    end

    it 'returns years for selected brand, model and fuel type' do
      get '/cars/years', params: { brand_name: 'SpecBrandYears', model: 'SpecModelYears', fuel_type_id: years_fuel_type.id }

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq([2020, 2021])
    end

    it 'returns 422 when required params are missing' do
      get '/cars/years', params: { brand_name: 'SpecBrandYears', model: 'SpecModelYears' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('brand_name, model and fuel_type_id are required')
    end
  end
end
