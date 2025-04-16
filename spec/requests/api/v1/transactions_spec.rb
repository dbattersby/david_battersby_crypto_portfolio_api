require 'rails_helper'

RSpec.describe "Api::V1::Transactions", type: :request do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, user: user) }
  let!(:transaction1) { create(:transaction, user: user, asset: asset, transaction_type: "buy", quantity: 2.0, price: 10000.0) }
  let!(:transaction2) { create(:transaction, user: user, asset: asset, transaction_type: "sell", quantity: 1.0, price: 15000.0) }
  
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/transactions" do
    it "returns http success with transactions" do
      get "/api/v1/transactions", headers: headers
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
    end
    
    it "returns unauthorized without valid auth" do
      get "/api/v1/transactions"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/transactions/:id" do
    it "returns http success with the specific transaction" do
      get "/api/v1/transactions/#{transaction1.id}", headers: headers
      
      expect(response).to have_http_status(:success)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["id"]).to eq(transaction1.id)
    end
    
    it "returns not found for invalid transaction id" do
      get "/api/v1/transactions/999999", headers: headers
      
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/transactions" do
    let(:valid_attributes) do
      { 
        transaction: {
          asset_id: asset.id,
          transaction_type: "buy",
          quantity: 1.5,
          price: 12000.0
        }
      }.to_json
    end
    
    it "creates a new transaction" do
      expect {
        post "/api/v1/transactions", params: valid_attributes, 
          headers: headers.merge('Content-Type' => 'application/json')
      }.to change(Transaction, :count).by(1)
      
      expect(response).to have_http_status(:created)
    end
    
    it "returns error for invalid parameters" do
      invalid_attributes = { 
        transaction: {
          asset_id: asset.id,
          transaction_type: "buy",
          quantity: -1.0,  # Invalid: must be > 0
          price: 12000.0
        }
      }.to_json
      
      post "/api/v1/transactions", params: invalid_attributes, 
        headers: headers.merge('Content-Type' => 'application/json')

      expect(response).not_to have_http_status(:success)
    end
  end
end
