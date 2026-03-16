# frozen_string_literal: true

RSpec.describe "Sessions (login location by IP)", type: :request do
  describe "POST /session" do
    context "when location can be resolved" do
      before do
        allow(Geoip::ResolveLocation).to receive(:for).with(ip: "8.8.8.8").and_return(
          { country: "United States", city: "New York" }
        )
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("8.8.8.8")
      end

      it "returns country and city in response (no DB write)" do
        post "/session"

        expect(response).to have_http_status(:created)
        expect(json_response["country"]).to eq("United States")
        expect(json_response["city"]).to eq("New York")
        expect(json_response["login_ip"]).to eq("8.8.8.8")
      end
    end

    context "when location cannot be resolved" do
      before do
        allow(Geoip::ResolveLocation).to receive(:for).and_return({ country: nil, city: nil })
      end

      it "returns 201 with nil location and does not fail" do
        post "/session"
        expect(response).to have_http_status(:created)
        expect(json_response["country"]).to be_nil
        expect(json_response["city"]).to be_nil
      end
    end
  end
end
