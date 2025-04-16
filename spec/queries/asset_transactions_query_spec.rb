require 'rails_helper'

RSpec.describe AssetTransactionsQuery do
  let(:user) { instance_double('User', id: 1) }
  let(:symbol) { 'btc' }
  
  describe "#call" do
    let(:asset) { instance_double('Asset', id: 1) }
    let(:transaction) { instance_double('Transaction') }
    let(:assets_relation) { double('ActiveRecord::Relation') }
    let(:transactions_relation) { double('ActiveRecord::Relation') }
    let(:includes_relation) { double('ActiveRecord::Relation') }
    
    before do
      # Mock the assets relation
      allow(user).to receive_message_chain(:assets, :where).with(symbol: symbol).and_return(assets_relation)
      allow(assets_relation).to receive(:pluck).with(:id).and_return([1])
      
      # Mock the transactions chain with proper order
      allow(Transaction).to receive(:where).with(asset_id: [1], user_id: 1).and_return(transactions_relation)
      allow(transactions_relation).to receive(:order).with(created_at: :desc).and_return(includes_relation)
      allow(includes_relation).to receive(:includes).with(:asset).and_return([transaction])
    end

    it "returns transactions for the given asset symbol" do
      query = AssetTransactionsQuery.new(user, symbol)
      expect(query.call).to eq([transaction])
    end
  end

  describe "#assets" do
    let(:assets_relation) { double('ActiveRecord::Relation') }
    
    before do
      allow(user).to receive_message_chain(:assets, :where).with(symbol: symbol).and_return(assets_relation)
    end
    
    it "returns assets for the given symbol" do
      query = AssetTransactionsQuery.new(user, symbol)
      expect(query.assets).to eq(assets_relation)
    end
  end
  
  describe "#asset_details" do
    let(:portfolio_query) { instance_double(PortfolioAssetsQuery) }
    let(:asset_details) { { symbol: symbol, name: 'Bitcoin', total_quantity: 1.5 } }
    
    before do
      allow(PortfolioAssetsQuery).to receive(:new).with(user).and_return(portfolio_query)
      allow(portfolio_query).to receive(:get_asset).with(symbol).and_return(asset_details)
    end
    
    it "gets asset details from PortfolioAssetsQuery" do
      query = AssetTransactionsQuery.new(user, symbol)
      expect(query.asset_details).to eq(asset_details)
    end
  end
  
  describe "#total_quantity" do
    let(:assets_relation) { double('ActiveRecord::Relation') }
    
    before do
      allow(user).to receive_message_chain(:assets, :where).with(symbol: symbol).and_return(assets_relation)
      allow(assets_relation).to receive(:sum).with(:quantity).and_return(1.5)
    end
    
    it "returns the sum of quantities for the given symbol" do
      query = AssetTransactionsQuery.new(user, symbol)
      expect(query.total_quantity).to eq(1.5)
    end
  end
end 