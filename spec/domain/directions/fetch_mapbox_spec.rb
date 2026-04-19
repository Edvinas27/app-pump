# frozen_string_literal: true

require "net/http"

# Requirements traceability (user story: route between two points):
# - AC1 (ticket: two mandatory address fields): implemented here as four required
#   coordinate parameters (start_lat, start_lng, end_lat, end_lng) on the API.
# - AC2: route is requested from Mapbox Directions API (URL and response handling).

RSpec.describe Directions::FetchMapbox do
  subject(:result) { described_class.for(params) }

  let(:base_params) do
    {
      start_lat: "54.6",
      start_lng: "25.2",
      end_lat: "54.7",
      end_lng: "25.3"
    }
  end
  let(:params) { base_params }

  let(:mapbox_token) { "test_mapbox_token" }
  let(:mapbox_ok_body) { { "code" => "Ok", "routes" => [] }.to_json }

  around do |example|
    previous = ENV.fetch("MAPBOX_ACCESS_TOKEN", nil)
    ENV["MAPBOX_ACCESS_TOKEN"] = mapbox_token
    example.run
    if previous.nil?
      ENV.delete("MAPBOX_ACCESS_TOKEN")
    else
      ENV["MAPBOX_ACCESS_TOKEN"] = previous
    end
  end

  describe "AC1: mandatory trip endpoints (coordinates)" do
    %i[start_lat start_lng end_lat end_lng].each do |key|
      context "when #{key} is missing" do
        let(:params) { base_params.except(key) }

        it "returns failure with missing parameter error" do
          expect(result[:success]).to be false
          expect(result[:errors]).to include("Missing parameter: #{key}")
        end
      end

      context "when #{key} is blank string" do
        let(:params) { base_params.merge(key => "") }

        it "returns failure with missing parameter error" do
          expect(result[:success]).to be false
          expect(result[:errors]).to include("Missing parameter: #{key}")
        end
      end
    end

    context "when a coordinate is not a number" do
      let(:params) { base_params.merge(start_lat: "not-a-number") }

      it "returns failure with invalid number error" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("Invalid number: start_lat")
      end
    end

    context "when start_lat is out of range" do
      let(:params) { base_params.merge(start_lat: "91") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("start_lat must be between -90 and 90")
      end
    end

    context "when start_lng is out of range" do
      let(:params) { base_params.merge(start_lng: "181") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("start_lng must be between -180 and 180")
      end
    end

    context "when end_lat is out of range" do
      let(:params) { base_params.merge(end_lat: "-91") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("end_lat must be between -90 and 90")
      end
    end

    context "when end_lng is out of range" do
      let(:params) { base_params.merge(end_lng: "-181") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("end_lng must be between -180 and 180")
      end
    end
  end

  describe "AC2: Mapbox Directions API" do
    context "when Mapbox access token is not configured" do
      let(:mapbox_token) { "" }

      it "returns failure without calling Mapbox" do
        expect(Net::HTTP).not_to receive(:get)
        expect(result[:success]).to be false
        expect(result[:errors]).to include("Mapbox access token is not configured")
      end
    end

    context "when Mapbox returns success" do
      it "calls Mapbox with driving profile, geojson geometry, coordinate order lng,lat;lng,lat, and encoded token" do
        expect(Net::HTTP).to receive(:get) do |uri|
          expect(uri).to be_a(URI::HTTPS)
          expect(uri.host).to eq("api.mapbox.com")
          expect(uri.path).to eq("/directions/v5/mapbox/driving/25.2,54.6;25.3,54.7")
          q = URI.decode_www_form(uri.query || "").to_h
          expect(q["geometries"]).to eq("geojson")
          expect(q["overview"]).to eq("full")
          expect(q["access_token"]).to eq(mapbox_token)
          mapbox_ok_body
        end

        expect(result[:success]).to be true
        expect(result[:data]).to eq(JSON.parse(mapbox_ok_body))
      end
    end

    context "when optional via coordinates are provided" do
      let(:params) do
        base_params.merge(via_lat: "54.65", via_lng: "25.25")
      end

      it "requests a path with start;via;end" do
        expect(Net::HTTP).to receive(:get) do |uri|
          expect(uri.path).to eq("/directions/v5/mapbox/driving/25.2,54.6;25.25,54.65;25.3,54.7")
          mapbox_ok_body
        end

        expect(result[:success]).to be true
      end
    end

    context "when only one of via_lat and via_lng is present" do
      let(:params) { base_params.merge(via_lat: "54.65", via_lng: "") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("via_lat and via_lng must both be present when using a waypoint")
      end
    end

    context "when via_lat is out of range" do
      let(:params) { base_params.merge(via_lat: "91", via_lng: "25.25") }

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to include("via_lat must be between -90 and 90")
      end
    end

    context "when Mapbox returns a non-Ok code" do
      let(:error_body) { { "code" => "NoRoute", "message" => "No route found" }.to_json }

      before do
        allow(Net::HTTP).to receive(:get).and_return(error_body)
      end

      it "returns failure with Mapbox message" do
        expect(result[:success]).to be false
        expect(result[:errors]).to eq([ "No route found" ])
      end
    end

    context "when Mapbox returns non-Ok without message" do
      let(:error_body) { { "code" => "InvalidInput" }.to_json }

      before do
        allow(Net::HTTP).to receive(:get).and_return(error_body)
      end

      it "returns generic routing failure" do
        expect(result[:success]).to be false
        expect(result[:errors]).to eq([ "Mapbox routing failed" ])
      end
    end

    context "when response body is not valid JSON" do
      before do
        allow(Net::HTTP).to receive(:get).and_return("<<<")
      end

      it "returns parse error" do
        expect(result[:success]).to be false
        expect(result[:errors].first).to start_with("Invalid response from Mapbox:")
      end
    end

    context "when Net::HTTP raises" do
      before do
        allow(Net::HTTP).to receive(:get).and_raise(StandardError.new("network down"))
      end

      it "returns wrapped error" do
        expect(result[:success]).to be false
        expect(result[:errors]).to eq([ "Directions request failed: network down" ])
      end
    end
  end
end
