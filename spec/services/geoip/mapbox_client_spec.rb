# frozen_string_literal: true

RSpec.describe Geoip::MapboxClient do
  let(:client) { described_class.new(access_token: "token", base_url: "https://api.mapbox.com/search/geocode/v6") }

  describe "#reverse_geocode" do
    context "when access_token is blank" do
      let(:client) { described_class.new(access_token: "") }

      it "returns nils without making a request" do
        expect(Net::HTTP).not_to receive(:start)
        expect(client.reverse_geocode(longitude: -73.99, latitude: 40.73)).to eq({ country: nil, city: nil })
      end
    end

    context "when API returns success with country and place" do
      let(:body) do
        {
          "features" => [
            {
              "properties" => {
                "context" => {
                  "country" => { "name" => "United States" },
                  "place" => { "name" => "New York" }
                }
              }
            }
          ]
        }.to_json
      end
      let(:response) { instance_double(Net::HTTPResponse, "is_a?" => true, body: body) }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:get).and_return(response)
      end

      it "returns country and city" do
        expect(client.reverse_geocode(longitude: -73.99, latitude: 40.73)).to eq(
          { country: "United States", city: "New York" }
        )
      end
    end

    context "when API returns non-success" do
      let(:response) { instance_double(Net::HTTPResponse, "is_a?" => false) }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:get).and_return(response)
      end

      it "returns nils" do
        expect(client.reverse_geocode(longitude: -73.99, latitude: 40.73)).to eq({ country: nil, city: nil })
      end
    end

    context "when API returns empty features" do
      let(:body) { { "features" => [] }.to_json }
      let(:response) { instance_double(Net::HTTPResponse, "is_a?" => true, body: body) }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:get).and_return(response)
      end

      it "returns nils" do
        expect(client.reverse_geocode(longitude: 0, latitude: 0)).to eq({ country: nil, city: nil })
      end
    end
  end
end
