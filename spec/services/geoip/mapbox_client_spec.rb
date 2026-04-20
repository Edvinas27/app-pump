# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe Geoip::MapboxClient do
  let(:token) { "test_mapbox_token" }
  let(:base_url) { "https://api.mapbox.test/search/geocode/v6" }

  subject(:client) { described_class.new(access_token: token, base_url: base_url) }

  def stub_http(response)
    fake_http = instance_double(Net::HTTP)
    captured = { uri: nil }
    allow(fake_http).to receive(:get) do |path|
      captured[:uri] = path
      response
    end
    allow(Net::HTTP).to receive(:start).and_yield(fake_http)
    captured
  end

  def http_success(body)
    Net::HTTPSuccess.new("1.1", "200", "OK").tap do |r|
      allow(r).to receive(:body).and_return(body)
    end
  end

  def http_error
    Net::HTTPBadGateway.new("1.1", "502", "Bad Gateway")
  end

  describe "#reverse_geocode" do
    context "when the access token is blank" do
      let(:token) { "" }

      it "returns nils without calling Mapbox" do
        expect(Net::HTTP).not_to receive(:start)

        expect(client.reverse_geocode(longitude: 25.2797, latitude: 54.6872))
          .to eq(country: nil, city: nil)
      end
    end

    context "on a successful response" do
      let(:body) do
        {
          "features" => [
            {
              "properties" => {
                "context" => {
                  "country" => { "name" => "Lithuania" },
                  "place" => { "name" => "Vilnius" }
                }
              }
            }
          ]
        }.to_json
      end

      it "returns country and city and includes all required query params" do
        captured = stub_http(http_success(body))

        result = client.reverse_geocode(longitude: 25.2797, latitude: 54.6872)

        expect(result).to eq(country: "Lithuania", city: "Vilnius")
        expect(captured[:uri]).to include("longitude=25.2797")
        expect(captured[:uri]).to include("latitude=54.6872")
        expect(captured[:uri]).to include("access_token=#{token}")
      end
    end

    context "when the response has no features" do
      it "returns nils" do
        stub_http(http_success({ "features" => [] }.to_json))

        expect(client.reverse_geocode(longitude: 1, latitude: 1))
          .to eq(country: nil, city: nil)
      end
    end

    context "when the response is non-2xx" do
      it "returns nils" do
        stub_http(http_error)

        expect(client.reverse_geocode(longitude: 1, latitude: 1))
          .to eq(country: nil, city: nil)
      end
    end

    context "when the response body is invalid JSON" do
      it "returns nils" do
        stub_http(http_success("<<not json>>"))

        expect(client.reverse_geocode(longitude: 1, latitude: 1))
          .to eq(country: nil, city: nil)
      end
    end

    context "when the HTTP call raises" do
      it "swallows the error and returns nils" do
        allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error)

        expect(client.reverse_geocode(longitude: 1, latitude: 1))
          .to eq(country: nil, city: nil)
      end
    end
  end
end
