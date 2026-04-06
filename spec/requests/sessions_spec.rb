# frozen_string_literal: true

RSpec.describe "Sessions", type: :request do
  describe "POST /sessions" do
    let(:password) { "Password1" }
    let!(:user) { create(:user, email: "login@example.com", password: password) }

    context "with valid email and password" do
      it "returns 200, user data, jwt token, and login_ip (GeoIP fields may be nil for private IP)" do
        post "/sessions", params: { email: "login@example.com", password: password }

        expect(response).to have_http_status(:ok)
        expect(json_response["user"]).to be_present
        expect(json_response["token"]).to be_present
        expect(json_response["login_ip"]).to be_present
        expect(json_response["user"]["email"]).to eq("login@example.com")
        expect(json_response["user"]["username"]).to eq(user.username)
        expect(json_response["user"]).not_to have_key("password_digest")
        expect(json_response["user"]).not_to have_key("password")

        payload = JsonWebToken.decode(json_response["token"])
        expect(payload["user_id"]).to eq(user.id)
      end
    end

    context "when client location resolves from IP" do
      before do
        allow(Geoip::ResolveLocation).to receive(:for).with(ip: "8.8.8.8").and_return(
          { country: "United States", city: "New York" }
        )
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("8.8.8.8")
      end

      it "returns country and city without persisting to DB" do
        post "/sessions", params: { email: "login@example.com", password: password }

        expect(response).to have_http_status(:ok)
        expect(json_response["country"]).to eq("United States")
        expect(json_response["city"]).to eq("New York")
        expect(json_response["login_ip"]).to eq("8.8.8.8")
        expect(json_response["token"]).to be_present
      end
    end

    context "when client location cannot be resolved" do
      before do
        allow(Geoip::ResolveLocation).to receive(:for).with(ip: "203.0.113.1").and_return(
          { country: nil, city: nil }
        )
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("203.0.113.1")
      end

      it "returns 200 with nil location and does not fail login" do
        post "/sessions", params: { email: "login@example.com", password: password }

        expect(response).to have_http_status(:ok)
        expect(json_response["country"]).to be_nil
        expect(json_response["city"]).to be_nil
        expect(json_response["login_ip"]).to eq("203.0.113.1")
        expect(json_response["token"]).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns 401 and clear error message when email is wrong" do
        post "/sessions", params: { email: "wrong@example.com", password: password }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("Neteisingas el. paštas arba slaptažodis")
        expect(json_response["user"]).to be_nil
      end

      it "returns 401 and clear error message when password is wrong" do
        post "/sessions", params: { email: "login@example.com", password: "WrongPass1" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("Neteisingas el. paštas arba slaptažodis")
        expect(json_response["user"]).to be_nil
      end

      it "returns 401 and clear error message when email is blank" do
        post "/sessions", params: { email: "", password: password }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("Neteisingas el. paštas arba slaptažodis")
      end

      it "returns 401 and clear error message when password is blank" do
        post "/sessions", params: { email: "login@example.com", password: "" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("Neteisingas el. paštas arba slaptažodis")
      end
    end
  end
end
