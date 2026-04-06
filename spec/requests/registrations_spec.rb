# frozen_string_literal: true

RSpec.describe "Registrations", type: :request do
  describe "POST /users" do
    let(:valid_params) do
      {
        email: "new@example.com",
        username: "newuser",
        password: "Password1"
      }
    end

    it "returns 201, user data and jwt token" do
      post "/users", params: valid_params

      expect(response).to have_http_status(:created)
      expect(json_response["user"]).to be_present
      expect(json_response["token"]).to be_present
      expect(json_response["user"]["email"]).to eq("new@example.com")

      payload = JsonWebToken.decode(json_response["token"])
      expect(payload["user_id"]).to eq(json_response["user"]["id"])
    end

    it "returns 422 with errors when params are invalid" do
      post "/users", params: { email: "", username: "", password: "short" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response["errors"]).to be_present
    end
  end
end
