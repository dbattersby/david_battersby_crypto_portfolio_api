require 'rails_helper'

RSpec.describe "Api::V1::Assets", type: :request do
  let(:user) { create(:user) }
  let(:jwt_headers) { auth_headers(user) }
  let(:asset) { create(:asset, user: user) }

  describe "GET /api/v1/assets" do
    it "returns http success" do
      get "/api/v1/assets", headers: jwt_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /api/v1/assets/:id" do
    it "returns http success" do
      get "/api/v1/assets/#{asset.id}", headers: jwt_headers
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /api/v1/assets" do
    it "returns http success" do
      asset_params = { 
        asset: { 
          name: "Bitcoin",
          symbol: "BTC",
          quantity: 1.0,
          purchase_price: 50000.0
        }
      }
      post "/api/v1/assets", params: asset_params, headers: jwt_headers, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /api/v1/assets/:id" do
    it "returns http success" do
      asset_params = { 
        asset: { 
          quantity: 2.0,
          purchase_price: 45000.0
        }
      }
      patch "/api/v1/assets/#{asset.id}", params: asset_params, headers: jwt_headers, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /api/v1/assets/:id" do
    it "returns http success" do
      delete "/api/v1/assets/#{asset.id}", headers: jwt_headers
      expect(response).to have_http_status(:success)
    end
  end
end
