# frozen_string_literal: true

RSpec.describe Geoip::ResolveLocation do
  describe ".for" do
    context "when IP resolves to coordinates and Mapbox returns country/city" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher).to receive(:fetch).with("8.8.8.8").and_return(
          { latitude: 40.73, longitude: -73.99 }
        )
        allow_any_instance_of(Geoip::MapboxClient).to receive(:reverse_geocode).with(
          longitude: -73.99, latitude: 40.73
        ).and_return({ country: "United States", city: "New York" })
      end

      it "returns country, city, and the resolved coordinates" do
        result = described_class.for(ip: "8.8.8.8")
        expect(result).to eq(
          country: "United States",
          city: "New York",
          latitude: 40.73,
          longitude: -73.99
        )
      end
    end

    context "when IP does not resolve to coordinates" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher).to receive(:fetch).with("192.168.1.1").and_return({})
      end

      it "returns nils without calling Mapbox" do
        expect_any_instance_of(Geoip::MapboxClient).not_to receive(:reverse_geocode)
        result = described_class.for(ip: "192.168.1.1")
        expect(result).to eq(country: nil, city: nil, latitude: nil, longitude: nil)
      end
    end

    context "when Mapbox returns empty" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher).to receive(:fetch).with("1.2.3.4").and_return(
          { latitude: 0.0, longitude: 0.0 }
        )
        allow_any_instance_of(Geoip::MapboxClient).to receive(:reverse_geocode).and_return(
          { country: nil, city: nil }
        )
      end

      it "returns nil country/city but keeps the resolved coordinates" do
        result = described_class.for(ip: "1.2.3.4")
        expect(result).to eq(country: nil, city: nil, latitude: 0.0, longitude: 0.0)
      end
    end
  end
end
