# frozen_string_literal: true

require "net/http"

RSpec.describe "Geocoding", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  let(:mapbox_body) do
    {
      "features" => [
        { "place_name" => "Konstitucijos pr. 1, Vilnius, Lithuania" }
      ]
    }.to_json
  end

  around do |example|
    previous = ENV.fetch("MAPBOX_ACCESS_TOKEN", nil)
    ENV["MAPBOX_ACCESS_TOKEN"] = "test_token_geocode"
    example.run
    if previous.nil?
      ENV.delete("MAPBOX_ACCESS_TOKEN")
    else
      ENV["MAPBOX_ACCESS_TOKEN"] = previous
    end
  end

  describe "GET /geocode/reverse" do
    context "when not authenticated" do
      it "returns 401" do
        get "/geocode/reverse", params: { lat: "54.6", lng: "25.2" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      it "returns 200 with label from Mapbox" do
        allow(Net::HTTP).to receive(:get).and_return(mapbox_body)

        get "/geocode/reverse", params: { lat: "54.6872", lng: "25.2797" }, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_response["label"]).to eq("Konstitucijos pr. 1, Vilnius, Lithuania")
      end

      it "returns 422 when lat is missing" do
        get "/geocode/reverse", params: { lng: "25.2" }, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["errors"]).to be_present
      end
    end
  end
end
