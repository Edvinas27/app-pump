# frozen_string_literal: true

require "net/http"

# AC1: mandatory coordinates on GET /directions (see domain spec for ticket vs API wording).
# AC2: successful response is Mapbox-shaped JSON from Directions::FetchMapbox.

RSpec.describe "Directions", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  let(:valid_params) do
    {
      start_lat: "54.6",
      start_lng: "25.2",
      end_lat: "54.7",
      end_lng: "25.3"
    }
  end

  let(:mapbox_ok_body) { { "code" => "Ok", "routes" => [ { "distance" => 1000 } ] }.to_json }

  around do |example|
    previous = ENV.fetch("MAPBOX_ACCESS_TOKEN", nil)
    ENV["MAPBOX_ACCESS_TOKEN"] = "test_token_for_request_spec"
    example.run
    if previous.nil?
      ENV.delete("MAPBOX_ACCESS_TOKEN")
    else
      ENV["MAPBOX_ACCESS_TOKEN"] = previous
    end
  end

  describe "GET /directions" do
    it "returns 401 when Authorization is missing" do
      get "/directions", params: valid_params

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to eq("Unauthorized")
    end

    context "AC1: when required parameters are missing" do
      it "returns 422 and errors when start_lat is missing" do
        get "/directions", params: valid_params.except(:start_lat), headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["errors"]).to include("Missing parameter: start_lat")
      end

      it "returns 422 when all coordinates are missing" do
        get "/directions", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        errors = json_response["errors"]
        expect(errors).to include("Missing parameter: start_lat")
        expect(errors).to include("Missing parameter: start_lng")
        expect(errors).to include("Missing parameter: end_lat")
        expect(errors).to include("Missing parameter: end_lng")
      end
    end

    context "AC1: when a coordinate is invalid" do
      it "returns 422 for non-numeric coordinate" do
        get "/directions", params: valid_params.merge(start_lat: "x"), headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["errors"]).to include("Invalid number: start_lat")
      end
    end

    context "AC2: when Mapbox returns success" do
      before do
        allow(Net::HTTP).to receive(:get).and_return(mapbox_ok_body)
      end

      it "returns 200 and Mapbox payload" do
        get "/directions", params: valid_params, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["code"]).to eq("Ok")
        expect(json_response["routes"]).to be_an(Array)
      end
    end

    context "when Mapbox token is not configured" do
      around do |example|
        previous = ENV.fetch("MAPBOX_ACCESS_TOKEN", nil)
        ENV.delete("MAPBOX_ACCESS_TOKEN")
        example.run
        ENV["MAPBOX_ACCESS_TOKEN"] = previous if previous
      end

      it "returns 422 with configuration error" do
        get "/directions", params: valid_params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["errors"]).to include("Mapbox access token is not configured")
      end
    end
  end
end
