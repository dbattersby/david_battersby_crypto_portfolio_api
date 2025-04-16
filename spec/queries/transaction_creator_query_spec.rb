require 'rails_helper'

RSpec.describe TransactionCreatorQuery do
  let(:user) { instance_double('User') }

  describe "#create_buy" do
    let(:buy_params) do
      {
        asset: {
          symbol: 'btc',
          name: 'Bitcoin',
          quantity: '1.5',
          initial_purchase_price: '25000.0'
        }
      }
    end

    let(:service_result) do
      {
        success: true,
        asset: instance_double('Asset'),
        transaction: instance_double('Transaction', quantity: 1.5)
      }
    end

    before do
      allow(TransactionCreator).to receive(:create_buy).and_return(service_result)
    end

    it "calls the TransactionCreator service with correct parameters" do
      query = TransactionCreatorQuery.new(user, buy_params)
      result = query.create_buy

      expect(TransactionCreator).to have_received(:create_buy).with(
        user,
        { symbol: 'btc', name: 'Bitcoin' },
        1.5,
        25000.0
      )

      expect(result).to eq(service_result)
    end

    context "with invalid inputs" do
      it "returns error when quantity is zero or negative" do
        params = buy_params.deep_dup
        params[:asset][:quantity] = '0'

        query = TransactionCreatorQuery.new(user, params)
        result = query.create_buy

        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include("Quantity must be greater than zero")
        expect(TransactionCreator).not_to have_received(:create_buy)
      end

      it "returns error when price is zero or negative" do
        params = buy_params.deep_dup
        params[:asset][:initial_purchase_price] = '-10'

        query = TransactionCreatorQuery.new(user, params)
        result = query.create_buy

        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include("Price must be greater than zero")
        expect(TransactionCreator).not_to have_received(:create_buy)
      end
    end
  end

  describe "#create_sell" do
    let(:sell_params) do
      {
        symbol: 'btc',
        transaction: {
          quantity: '1.5',
          price: '30000.0'
        }
      }
    end

    let(:service_result) do
      {
        success: true,
        quantity_sold: 1.5,
        assets: [ 1, 2 ],
        transactions: [ instance_double('Transaction') ]
      }
    end

    before do
      allow(TransactionCreator).to receive(:create_sell).and_return(service_result)
    end

    it "calls the TransactionCreator service with correct parameters" do
      query = TransactionCreatorQuery.new(user, sell_params)
      result = query.create_sell

      expect(TransactionCreator).to have_received(:create_sell).with(
        user,
        'btc',
        1.5,
        30000.0
      )

      expect(result).to eq(service_result)
    end

    context "with invalid inputs" do
      it "returns error when quantity is zero or negative" do
        params = sell_params.deep_dup
        params[:transaction][:quantity] = '0'

        query = TransactionCreatorQuery.new(user, params)
        result = query.create_sell

        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include("Quantity must be greater than zero")
        expect(TransactionCreator).not_to have_received(:create_sell)
      end

      it "returns error when price is zero or negative" do
        params = sell_params.deep_dup
        params[:transaction][:price] = '-10'

        query = TransactionCreatorQuery.new(user, params)
        result = query.create_sell

        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include("Price must be greater than zero")
        expect(TransactionCreator).not_to have_received(:create_sell)
      end
    end
  end
end
