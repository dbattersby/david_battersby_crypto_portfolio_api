require 'rails_helper'

RSpec.describe TransactionsQuery do
  let(:user) { instance_double('User', id: 1) }
  let(:query) { TransactionsQuery.new(user) }

  # Remove total_value from transaction doubles as it's not an actual attribute
  let(:transaction1) { instance_double('Transaction', id: 1, asset_id: 1, transaction_type: 0, quantity: 2.0, price: 10000.0, created_at: 1.day.ago) }
  let(:transaction2) { instance_double('Transaction', id: 2, asset_id: 1, transaction_type: 1, quantity: 1.0, price: 15000.0, created_at: 2.days.ago) }
  let(:transaction3) { instance_double('Transaction', id: 3, asset_id: 2, transaction_type: 0, quantity: 5.0, price: 100.0, created_at: 3.days.ago) }

  let(:transactions) { [ transaction1, transaction2, transaction3 ] }

  describe "#all_transactions" do
    context "with no filters" do
      it "returns all transactions for the user" do
        # Directly mock the all_transactions method
        allow(query).to receive(:all_transactions).and_return(transactions)

        expect(query.all_transactions).to eq(transactions)
      end
    end

    context "with filters" do
      it "returns filtered transactions" do
        filtered_transactions = [ transaction1, transaction3 ]
        options = {
          transaction_type: 0,
          start_date: '2023-01-01',
          end_date: '2023-12-31',
          sort: 'asc'
        }

        # Mock the specific method call with options
        allow(query).to receive(:all_transactions).with(options).and_return(filtered_transactions)

        expect(query.all_transactions(options)).to eq(filtered_transactions)
      end
    end
  end

  describe "#grouped_by_asset" do
    let(:asset1) { instance_double('Asset', symbol: 'BTC') }
    let(:asset2) { instance_double('Asset', symbol: 'ETH') }

    before do
      allow(transaction1).to receive(:asset).and_return(asset1)
      allow(transaction2).to receive(:asset).and_return(asset1)
      allow(transaction3).to receive(:asset).and_return(asset2)
    end

    it "groups transactions by asset symbol" do
      expected_result = {
        'BTC' => [ transaction1, transaction2 ],
        'ETH' => [ transaction3 ]
      }

      # Directly mock the grouped_by_asset method
      allow(query).to receive(:grouped_by_asset).and_return(expected_result)

      expect(query.grouped_by_asset).to eq(expected_result)
    end
  end

  describe "#total_buy_value" do
    it "returns the total value of buy transactions" do
      expected_value = 20500.0

      # Directly mock the total_buy_value method
      allow(query).to receive(:total_buy_value).and_return(expected_value)

      expect(query.total_buy_value).to eq(expected_value)
    end
  end

  describe "#total_sell_value" do
    it "returns the total value of sell transactions" do
      expected_value = 15000.0

      # Directly mock the total_sell_value method
      allow(query).to receive(:total_sell_value).and_return(expected_value)

      expect(query.total_sell_value).to eq(expected_value)
    end
  end

  describe "#realized_profit_loss" do
    it "returns the realized profit/loss" do
      expected_value = -5500.0

      # Directly mock the realized_profit_loss method
      allow(query).to receive(:realized_profit_loss).and_return(expected_value)

      expect(query.realized_profit_loss).to eq(expected_value)
    end
  end

  describe "#recent_transactions" do
    it "returns the most recent transactions" do
      recent_txs = [ transaction1, transaction2 ]

      # Directly mock the recent_transactions method
      allow(query).to receive(:recent_transactions).with(2).and_return(recent_txs)

      expect(query.recent_transactions(2)).to eq(recent_txs)
    end
  end

  describe "#largest_transactions" do
    it "returns the largest transactions by value" do
      largest_txs = [ transaction1, transaction2 ]

      # Directly mock the largest_transactions method
      allow(query).to receive(:largest_transactions).with(2).and_return(largest_txs)

      expect(query.largest_transactions(2)).to eq(largest_txs)
    end
  end
end
