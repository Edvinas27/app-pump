# frozen_string_literal: true

RSpec.describe Directions::RouteDistance do
  describe ".km_from_meters" do
    it "converts meters to kilometres rounded to two decimal places" do
      expect(described_class.km_from_meters(1234.56)).to eq(1.23)
      expect(described_class.km_from_meters(1000)).to eq(1.0)
      expect(described_class.km_from_meters(100)).to eq(0.1)
    end

    it "returns nil when metres are nil" do
      expect(described_class.km_from_meters(nil)).to be_nil
    end
  end

  describe ".enrich_mapbox_payload" do
    it "adds distance_km to each route from Mapbox distance in metres" do
      payload = {
        "code" => "Ok",
        "routes" => [
          { "distance" => 5000, "duration" => 600 },
          { "distance" => 1500.25 }
        ]
      }

      enriched = described_class.enrich_mapbox_payload(payload)

      expect(enriched["routes"][0]["distance"]).to eq(5000)
      expect(enriched["routes"][0]["distance_km"]).to eq(5.0)
      expect(enriched["routes"][1]["distance_km"]).to eq(1.5)
    end

    it "returns the original hash when routes key is missing" do
      payload = { "code" => "Ok" }
      expect(described_class.enrich_mapbox_payload(payload)).to eq(payload)
    end
  end
end
