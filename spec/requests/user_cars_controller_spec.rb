# frozen_string_literal: true

RSpec.describe UserCarsController, type: :request do
  let(:user) { create(:user) }
  let(:fuel_type) { create(:fuel_type, name: "Petrol") }
  let(:car) { create(:car, brand_name: "Audi", model: "A4", year: 2022, co2_emission: 120, fuel_type: fuel_type) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /me/cars" do
    it "assigns a car to a user" do
      expect do
        post "/me/cars", params: { car_id: car.id }, headers: headers
      end.to change(UserCar, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response["id"]).to eq(car.id)
      expect(json_response["fuel_type"]["name"]).to eq("Petrol")
    end

    it "returns 422 for duplicate assignment" do
      create(:user_car, user: user, car: car)

      post "/me/cars", params: { car_id: car.id }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response["errors"]).to have_key("car_id")
    end

    it "returns 401 when auth header is missing" do
      post "/me/cars", params: { car_id: car.id }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to eq("Unauthorized")
    end
  end

  describe "GET /me/cars" do
    it "returns all cars assigned to user" do
      create(:user_car, user: user, car: car)

      get "/me/cars", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(1)
      expect(json_response.first["brand_name"]).to eq("Audi")
      expect(json_response.first["year"]).to eq(2022)
    end

    it "returns 401 when auth header is missing" do
      get "/me/cars"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to eq("Unauthorized")
    end
  end
end
