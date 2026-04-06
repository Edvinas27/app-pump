# frozen_string_literal: true

RSpec.describe "Sessions", type: :request do
  describe "POST /sessions" do
    let(:password) { "Password1" }
    let!(:user) { create(:user, email: "login@example.com", password: password) }

    context "with valid email and password" do
      it "returns 200 and user data" do
        post "/sessions", params: { email: "login@example.com", password: password }

        expect(response).to have_http_status(:ok)
        expect(json_response["user"]).to be_present
        expect(json_response["user"]["email"]).to eq("login@example.com")
        expect(json_response["user"]["username"]).to eq(user.username)
        expect(json_response["user"]).not_to have_key("password_digest")
        expect(json_response["user"]).not_to have_key("password")
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
