# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe Geoip::IpCoordinatesFetcher do
  subject(:fetcher) { described_class.new(base_url: "http://ip-api.test/json") }

  def stub_http(response)
    fake_http = instance_double(Net::HTTP)
    allow(fake_http).to receive(:get).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(fake_http)
  end

  def http_success(body)
    Net::HTTPSuccess.new("1.1", "200", "OK").tap do |r|
      allow(r).to receive(:body).and_return(body)
    end
  end

  def http_error
    Net::HTTPNotFound.new("1.1", "404", "Not Found")
  end

  describe "#fetch" do
    context "when IP is blank or invalid" do
      it "returns {} for nil" do
        expect(Net::HTTP).not_to receive(:start)
        expect(fetcher.fetch(nil)).to eq({})
      end

      it "returns {} for empty string" do
        expect(Net::HTTP).not_to receive(:start)
        expect(fetcher.fetch("")).to eq({})
      end

      it "returns {} for a malformed IP" do
        expect(Net::HTTP).not_to receive(:start)
        expect(fetcher.fetch("not-an-ip")).to eq({})
      end
    end

    context "when IP is private / loopback" do
      %w[127.0.0.1 ::1 10.0.0.5 192.168.1.10 172.20.5.5].each do |ip|
        it "short-circuits to {} for #{ip} without hitting the network" do
          expect(Net::HTTP).not_to receive(:start)
          expect(fetcher.fetch(ip)).to eq({})
        end
      end
    end

    context "when the remote API returns valid coords" do
      it "parses lat/lon into floats" do
        stub_http(http_success({ "lat" => 54.6872, "lon" => 25.2797 }.to_json))

        expect(fetcher.fetch("8.8.8.8")).to eq(latitude: 54.6872, longitude: 25.2797)
      end
    end

    context "when the remote API returns non-2xx" do
      it "returns {}" do
        stub_http(http_error)

        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end
    end

    context "when the response body is invalid JSON" do
      it "returns {}" do
        stub_http(http_success("<<not json>>"))

        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end
    end

    context "when the response is missing lat/lon" do
      it "returns {}" do
        stub_http(http_success({ "status" => "fail" }.to_json))

        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end
    end

    context "when the HTTP call raises" do
      it "swallows Timeout::Error and returns {}" do
        allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error)

        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end

      it "swallows SocketError and returns {}" do
        allow(Net::HTTP).to receive(:start).and_raise(SocketError.new("boom"))

        expect(fetcher.fetch("8.8.8.8")).to eq({})
      end
    end
  end
end
