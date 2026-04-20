# frozen_string_literal: true

RSpec.describe "Sessions", type: :request do
  describe "POST /sessions" do
    let(:password) { "Password1" }
    let!(:user) { create(:user, email: "login@example.com", password: password) }

    before do
      allow_any_instance_of(Geoip::IpCoordinatesFetcher).to receive(:fetch).and_return({})
      allow_any_instance_of(Geoip::MapboxClient).to receive(:reverse_geocode)
        .and_return(country: nil, city: nil)
    end

    context "with valid email and password" do
      it "returns 200, user data and jwt token" do
        post "/sessions", params: { email: "login@example.com", password: password }

        expect(response).to have_http_status(:ok)
        expect(json_response["user"]).to be_present
        expect(json_response["token"]).to be_present
        expect(json_response["user"]["email"]).to eq("login@example.com")
        expect(json_response["user"]["username"]).to eq(user.username)
        expect(json_response["user"]).not_to have_key("password_digest")
        expect(json_response["user"]).not_to have_key("password")

        payload = JsonWebToken.decode(json_response["token"])
        expect(payload["user_id"]).to eq(user.id)
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

      it "does not perform any GeoIP lookup on 401" do
        expect_any_instance_of(Geoip::IpCoordinatesFetcher).not_to receive(:fetch)
        expect_any_instance_of(Geoip::MapboxClient).not_to receive(:reverse_geocode)

        post "/sessions", params: { email: "login@example.com", password: "WrongPass1" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "GeoIP resolution in the login response" do
      let(:valid_params) { { email: "login@example.com", password: password } }

      context "when the request comes from a public IP and Mapbox resolves the place" do
        before do
          allow_any_instance_of(Geoip::IpCoordinatesFetcher)
            .to receive(:fetch)
            .and_return(latitude: 54.6872, longitude: 25.2797)

          allow_any_instance_of(Geoip::MapboxClient)
            .to receive(:reverse_geocode)
            .with(longitude: 25.2797, latitude: 54.6872)
            .and_return(country: "Lithuania", city: "Vilnius")
        end

        it "returns country, city, latitude, longitude and the login_ip" do
          post "/sessions", params: valid_params, env: { "REMOTE_ADDR" => "8.8.8.8" }

          expect(response).to have_http_status(:ok)
          expect(json_response["country"]).to eq("Lithuania")
          expect(json_response["city"]).to eq("Vilnius")
          expect(json_response["latitude"]).to eq(54.6872)
          expect(json_response["longitude"]).to eq(25.2797)
          expect(json_response["login_ip"]).to be_a(String).and be_present
        end
      end

      context "when the request comes from a private / loopback IP" do
        it "keeps login successful and returns nil geo fields without calling the Mapbox client" do
          expect_any_instance_of(Geoip::MapboxClient).not_to receive(:reverse_geocode)

          post "/sessions", params: valid_params, env: { "REMOTE_ADDR" => "127.0.0.1" }

          expect(response).to have_http_status(:ok)
          expect(json_response).to include(
            "country" => nil,
            "city" => nil,
            "latitude" => nil,
            "longitude" => nil,
            "login_ip" => "127.0.0.1"
          )
        end
      end

      context "when coordinates resolve but Mapbox reverse lookup fails" do
        before do
          allow_any_instance_of(Geoip::IpCoordinatesFetcher)
            .to receive(:fetch)
            .and_return(latitude: 54.6872, longitude: 25.2797)

          allow_any_instance_of(Geoip::MapboxClient)
            .to receive(:reverse_geocode)
            .and_return(country: nil, city: nil)
        end

        it "keeps the coordinates and returns nil country/city, login still 200" do
          post "/sessions", params: valid_params, env: { "REMOTE_ADDR" => "8.8.8.8" }

          expect(response).to have_http_status(:ok)
          expect(json_response["latitude"]).to eq(54.6872)
          expect(json_response["longitude"]).to eq(25.2797)
          expect(json_response["country"]).to be_nil
          expect(json_response["city"]).to be_nil
          expect(json_response["login_ip"]).to be_a(String).and be_present
        end
      end
    end
  end
end
