require 'rails_helper'

RSpec.describe CryptoApi do
  describe ".get_price" do
    let(:symbol) { "btc" }
    let(:price) { 30000.0 }

    before do
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)
      allow(CryptocurrencyService).to receive(:get_current_price).and_return(price)
    end

    it "gets price from CryptocurrencyService when not in cache" do
      expect(CryptoApi.get_price(symbol)).to eq(price)
      expect(CryptocurrencyService).to have_received(:get_current_price).with(symbol)
    end

    it "reads from cache if price is available" do
      allow(Rails.cache).to receive(:read).with("crypto_price:#{symbol}").and_return(price)
      
      expect(CryptoApi.get_price(symbol)).to eq(price)
      expect(CryptocurrencyService).not_to have_received(:get_current_price)
    end

    it "writes to cache when fetching a fresh price" do
      CryptoApi.get_price(symbol)
      
      expect(Rails.cache).to have_received(:write)
        .with("crypto_price:#{symbol}", price, expires_in: CryptoApi::CACHE_EXPIRY)
    end
  end

  describe ".get_prices" do
    let(:symbols) { ["btc", "eth"] }
    let(:prices) { { "btc" => 30000.0, "eth" => 2000.0 } }

    before do
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)
      allow(CryptocurrencyService).to receive(:get_current_price) do |symbol|
        prices[symbol]
      end
      allow(Coin).to receive(:where).and_return([])
    end

    it "returns prices for multiple symbols" do
      result = CryptoApi.get_prices(symbols)
      
      expect(result["btc"]).to eq(30000.0)
      expect(result["eth"]).to eq(2000.0)
    end

    it "uses cache for symbols that are cached" do
      allow(Rails.cache).to receive(:read).with("crypto_price:btc").and_return(prices["btc"])
      
      CryptoApi.get_prices(symbols)
      
      # Should only call get_current_price for eth, not btc
      expect(CryptocurrencyService).to have_received(:get_current_price).with("eth")
      expect(CryptocurrencyService).not_to have_received(:get_current_price).with("btc")
    end
  end

  describe ".refresh_price" do
    let(:symbol) { "btc" }
    let(:price) { 30000.0 }

    before do
      allow(Rails.cache).to receive(:write)
      allow(CryptocurrencyService).to receive(:get_current_price).and_return(price)
    end

    it "forces a refresh from CryptocurrencyService" do
      CryptoApi.refresh_price(symbol)
      
      expect(CryptocurrencyService).to have_received(:get_current_price)
        .with(symbol, force_refresh: true)
    end

    it "updates the cache with the new price" do
      CryptoApi.refresh_price(symbol)
      
      expect(Rails.cache).to have_received(:write)
        .with("crypto_price:#{symbol}", price, expires_in: CryptoApi::CACHE_EXPIRY)
    end
  end
end 