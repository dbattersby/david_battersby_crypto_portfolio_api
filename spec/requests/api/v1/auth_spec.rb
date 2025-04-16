require 'rails_helper'

RSpec.describe "Api::V1::Auths", type: :request do
  let(:user) { create(:user) }
  let(:jwt_headers) { auth_headers(user) }
  let(:user_attributes) { attributes_for(:user, email: "test#{rand(1000)}@example.com") }
  let(:login_user) { create(:user, password: "password123") }
  let(:new_user) { build(:user, email: "test#{rand(1000)}@example.com") }

  # Common headers for JSON requests
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

  # Request params - Note: the controller directly accesses params in the method with params.permit
  let(:signup_params) { user_attributes }
  let(:valid_login_params) { { email: login_user.email, password: "password123" } }
  let(:invalid_login_params) { { email: login_user.email, password: "wrongpassword" } }

  describe "POST /auth/signup" do
    it "registers a new user" do
      post "/api/v1/auth/signup", params: signup_params, headers: json_headers, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include("message" => "User registered successfully")
    end
  end

  describe "POST /auth/login" do
    it "logs in an existing user" do
      post "/api/v1/auth/login", params: valid_login_params, headers: json_headers, as: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include("message" => "Logged in successfully")
    end
    
    it "returns error with invalid credentials" do
      post "/api/v1/auth/login", params: invalid_login_params, headers: json_headers, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe "DELETE /auth/logout" do
    it "logs out a user" do
      delete "/api/v1/auth/logout", headers: jwt_headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include("message" => "Logged out successfully")
    end
  end
end
