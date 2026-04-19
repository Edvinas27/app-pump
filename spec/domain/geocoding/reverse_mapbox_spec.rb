# frozen_string_literal: true

require "net/http"

RSpec.describe Geocoding::ReverseMapbox do
  let(:mapbox_token) { "test_mapbox_token" }

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

  describe ".for" do
    context "when lat or lng is missing" do
      it "returns failure" do
        result = described_class.for({ lat: "54.6" })

        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Missing parameter: lng")
      end
    end

    context "when Mapbox returns a feature" do
      let(:body) do
        {
          "features" => [
            { "place_name" => "Example Street 1, Vilnius, Lithuania" }
          ]
        }.to_json
      end

      it "returns place_name as label" do
        allow(Net::HTTP).to receive(:get).and_return(body)

        result = described_class.for({ lat: "54.6872", lng: "25.2797" })

        expect(result[:success]).to be(true)
        expect(result[:label]).to eq("Example Street 1, Vilnius, Lithuania")
      end
    end

    context "when Mapbox returns no features" do
      let(:body) { { "features" => [] }.to_json }

      it "returns success with nil label" do
        allow(Net::HTTP).to receive(:get).and_return(body)

        result = described_class.for({ lat: "54.6872", lng: "25.2797" })

        expect(result[:success]).to be(true)
        expect(result[:label]).to be_nil
      end
    end

    context "when token is missing" do
      let(:mapbox_token) { "" }

      it "returns failure without calling Mapbox" do
        expect(Net::HTTP).not_to receive(:get)

        result = described_class.for({ lat: "54.6", lng: "25.2" })

        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Mapbox access token is not configured")
      end
    end
  end
end
