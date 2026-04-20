# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geoip::ResolveLocation do
  let(:ip) { "8.8.8.8" }

  describe ".for" do
    context "when the IP has no resolvable coordinates" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher).to receive(:fetch).and_return({})
      end

      it "returns EMPTY and does not call MapboxClient" do
        expect_any_instance_of(Geoip::MapboxClient).not_to receive(:reverse_geocode)

        result = described_class.for(ip: ip)

        expect(result).to eq(described_class::EMPTY)
      end
    end

    context "when coordinates are resolved and Mapbox returns a place" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher)
          .to receive(:fetch)
          .and_return(latitude: 54.6872, longitude: 25.2797)

        allow_any_instance_of(Geoip::MapboxClient)
          .to receive(:reverse_geocode)
          .with(longitude: 25.2797, latitude: 54.6872)
          .and_return(country: "Lithuania", city: "Vilnius")
      end

      it "merges coordinates with country and city" do
        result = described_class.for(ip: ip)

        expect(result).to eq(
          country: "Lithuania",
          city: "Vilnius",
          latitude: 54.6872,
          longitude: 25.2797
        )
      end
    end

    context "when coordinates resolve but Mapbox returns nils" do
      before do
        allow_any_instance_of(Geoip::IpCoordinatesFetcher)
          .to receive(:fetch)
          .and_return(latitude: 54.6872, longitude: 25.2797)

        allow_any_instance_of(Geoip::MapboxClient)
          .to receive(:reverse_geocode)
          .and_return(country: nil, city: nil)
      end

      it "keeps coordinates and country/city as nil" do
        result = described_class.for(ip: ip)

        expect(result).to eq(
          country: nil,
          city: nil,
          latitude: 54.6872,
          longitude: 25.2797
        )
      end
    end
  end
end
