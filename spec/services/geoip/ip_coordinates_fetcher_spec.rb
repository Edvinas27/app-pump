# frozen_string_literal: true

RSpec.describe Geoip::IpCoordinatesFetcher do
  let(:fetcher) { described_class.new }

  describe "#fetch" do
    it "returns empty hash for blank ip" do
      expect(fetcher.fetch("")).to eq({})
      expect(fetcher.fetch(nil)).to eq({})
    end

    it "returns empty hash for localhost" do
      expect(Net::HTTP).not_to receive(:start)
      expect(fetcher.fetch("127.0.0.1")).to eq({})
    end

    context "when API returns lat/lon" do
      let(:body) { { "lat" => 40.7128, "lon" => -74.0060 }.to_json }
      let(:response) { instance_double(Net::HTTPResponse, "is_a?" => true, body: body) }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:get).and_return(response)
      end

      it "returns latitude and longitude" do
        expect(fetcher.fetch("8.8.8.8")).to eq({ latitude: 40.7128, longitude: -74.0060 })
      end
    end

    context "when API returns error" do
      let(:response) { instance_double(Net::HTTPResponse, "is_a?" => false) }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:get).and_return(response)
      end

      it "returns empty hash" do
        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end
    end
  end
end
