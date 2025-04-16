require 'rails_helper'

RSpec.describe PortfolioSummaryQuery do
  let(:user) { instance_double('User') }
  let(:portfolio_query) { instance_double(PortfolioAssetsQuery) }
  let(:query) { PortfolioSummaryQuery.new(user) }

  let(:portfolio_data) do
    {
      'btc' => {
        symbol: 'btc',
        name: 'Bitcoin',
        total_quantity: 2.0,
        avg_purchase_price: 20000.0,
        current_price: 25000.0,
        total_value: 50000.0,
        profit_loss: 25.0
      },
      'eth' => {
        symbol: 'eth',
        name: 'Ethereum',
        total_quantity: 10.0,
        avg_purchase_price: 1500.0,
        current_price: 1300.0,
        total_value: 13000.0,
        profit_loss: -13.33
      },
      'sol' => {
        symbol: 'sol',
        name: 'Solana',
        total_quantity: 100.0,
        avg_purchase_price: 50.0,
        current_price: 75.0,
        total_value: 7500.0,
        profit_loss: 50.0
      }
    }
  end

  before do
    allow(PortfolioAssetsQuery).to receive(:new).with(user, force_refresh: false).and_return(portfolio_query)
    allow(portfolio_query).to receive(:call).and_return(portfolio_data)
  end

  describe '#call' do
    it "returns a complete portfolio summary" do
      result = query.call

      # Verify the total value calculation (sum of all asset values)
      expect(result[:total_value]).to eq(50000.0 + 13000.0 + 7500.0)
      expect(result[:asset_count]).to eq(3)
      expect(result[:assets].size).to eq(3)
      expect(result[:best_performers].first[:symbol]).to eq('sol')
      expect(result[:worst_performers].first[:symbol]).to eq('eth')

      # Calculate the expected percentage for BTC: 50000/70500 * 100 = ~70.9%
      expect(result[:distribution]['btc'][:percentage]).to be_within(0.1).of(70.9)

      # Calculate the expected absolute profit/loss:
      # (Current value - Purchase value)
      # Current value = 50000 + 13000 + 7500 = 70500
      # Purchase value = (2 * 20000) + (10 * 1500) + (100 * 50) = 40000 + 15000 + 5000 = 60000
      # Profit/Loss = 70500 - 60000 = 10500
      expect(result[:total_profit_loss][:absolute]).to be_within(0.1).of(10500.0)

      # Verify percentage is also correct: 10500/60000 * 100 = 17.5%
      expect(result[:total_profit_loss][:percentage]).to be_within(0.1).of(17.5)

      expect(result[:last_updated]).to be_present
    end

    it "returns an empty hash when there are no assets" do
      allow(portfolio_query).to receive(:call).and_return({})
      expect(query.call).to eq({})
    end
  end

  describe '#calculate_total_value' do
    it "sums the total value of all assets" do
      expect(query.calculate_total_value(portfolio_data)).to eq(70500.0)
    end
  end

  describe '#find_best_performers' do
    it "returns assets with positive profit/loss, sorted by profit/loss descending" do
      best = query.find_best_performers(portfolio_data)

      expect(best.size).to eq(2)
      expect(best.first[:symbol]).to eq('sol')
      expect(best.first[:profit_loss]).to eq(50.0)
      expect(best.last[:symbol]).to eq('btc')
    end

    it "limits the number of results" do
      best = query.find_best_performers(portfolio_data, 1)
      expect(best.size).to eq(1)
    end
  end

  describe '#find_worst_performers' do
    it "returns assets with negative profit/loss, sorted by profit/loss ascending" do
      worst = query.find_worst_performers(portfolio_data)

      expect(worst.size).to eq(1)
      expect(worst.first[:symbol]).to eq('eth')
      expect(worst.first[:profit_loss]).to eq(-13.33)
    end

    it "limits the number of results" do
      # Add another asset with negative profit/loss for testing limit
      test_data = portfolio_data.merge({
        'dot' => {
          symbol: 'dot',
          name: 'Polkadot',
          total_quantity: 200.0,
          avg_purchase_price: 20.0,
          current_price: 18.0,
          total_value: 3600.0,
          profit_loss: -10.0
        }
      })

      worst = query.find_worst_performers(test_data, 1)
      expect(worst.size).to eq(1)
      expect(worst.first[:symbol]).to eq('eth')
    end
  end

  describe '#calculate_distribution' do
    it "calculates percentage distribution of portfolio by value" do
      distribution = query.calculate_distribution(portfolio_data)

      expect(distribution['btc'][:percentage]).to be_within(0.1).of(70.9)
      expect(distribution['eth'][:percentage]).to be_within(0.1).of(18.4)
      expect(distribution['sol'][:percentage]).to be_within(0.1).of(10.6)
    end

    it "returns an empty hash if total value is zero" do
      empty_data = {}
      expect(query.calculate_distribution(empty_data)).to eq({})
    end
  end

  describe '#calculate_total_profit_loss' do
    it "calculates both absolute and percentage profit/loss" do
      result = query.calculate_total_profit_loss(portfolio_data)

      # (2.0 * 25000 - 2.0 * 20000) + (10.0 * 1300 - 10.0 * 1500) + (100.0 * 75 - 100.0 * 50)
      # = 10000 - 2000 + 2500 = 10500
      expected_absolute = 10500.0

      # Percentage: 10500 / (2.0 * 20000 + 10.0 * 1500 + 100.0 * 50) = 10500 / 60000 = 0.175 = 17.5%
      expected_percentage = 17.5

      expect(result[:absolute]).to be_within(0.1).of(expected_absolute)
      expect(result[:percentage]).to be_within(0.1).of(expected_percentage)
    end

    it "returns zeros if portfolio is empty" do
      result = query.calculate_total_profit_loss({})
      expect(result[:absolute]).to eq(0)
      expect(result[:percentage]).to eq(0)
    end
  end

  describe '#recent_activity' do
    let(:transaction1) { instance_double('Transaction', id: 1, asset: double('Asset', symbol: 'btc', name: 'Bitcoin'),
                        transaction_type: 'buy', quantity: 1.0, price: 20000.0, created_at: 1.day.ago) }
    let(:transaction2) { instance_double('Transaction', id: 2, asset: double('Asset', symbol: 'eth', name: 'Ethereum'),
                        transaction_type: 'sell', quantity: 2.0, price: 1500.0, created_at: 2.days.ago) }

    before do
      allow(user).to receive(:id).and_return(123)
      allow(Transaction).to receive(:where).with(user_id: 123).and_return(double('ActiveRecord::Relation',
        order: double('ActiveRecord::Relation',
          limit: double('ActiveRecord::Relation',
            includes: [ transaction1, transaction2 ]
          )
        )
      ))
    end

    it "returns recent transactions with details" do
      allow(transaction1).to receive(:quantity).and_return(1.0)
      allow(transaction1).to receive(:price).and_return(20000.0)

      allow(transaction2).to receive(:quantity).and_return(2.0)
      allow(transaction2).to receive(:price).and_return(1500.0)

      result = query.recent_activity

      expect(result.size).to eq(2)
      expect(result.first[:symbol]).to eq('btc')
      expect(result.first[:transaction_type]).to eq('buy')
      expect(result.first[:value]).to eq(20000.0)

      expect(result.last[:symbol]).to eq('eth')
      expect(result.last[:transaction_type]).to eq('sell')
      expect(result.last[:value]).to eq(3000.0)
    end
  end
end
