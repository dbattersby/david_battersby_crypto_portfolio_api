class CryptocurrencyService
  require "net/http"
  require "json"

  def self.fetch_top_cryptocurrencies(limit = 100)
    # In a real application, this would make an API call to CoinGecko or similar
    # Example API endpoint: https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1

    begin
      uri = URI("https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=#{limit}&page=1")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        coins_data = data.map do |coin|
          {
            id: coin["id"],
            symbol: coin["symbol"].upcase,
            name: coin["name"],
            current_price: coin["current_price"],
            image: coin["image"],
            price_change_24h: coin["price_change_percentage_24h"]
          }
        end

        # Update the coins in the database
        update_coins_in_database(coins_data)

        coins_data
      else
        # Fall back to static data if API call fails
        coins_data = fallback_cryptocurrencies
        update_coins_in_database(coins_data)
        coins_data
      end
    rescue => e
      Rails.logger.error "Error fetching cryptocurrencies: #{e.message}"
      coins_data = fallback_cryptocurrencies
      update_coins_in_database(coins_data)
      coins_data
    end
  end

  def self.fallback_cryptocurrencies
    [
      { id: "bitcoin", symbol: "BTC", name: "Bitcoin", current_price: 29000, price_change_24h: 1.2 },
      { id: "ethereum", symbol: "ETH", name: "Ethereum", current_price: 1800, price_change_24h: -0.5 },
      { id: "tether", symbol: "USDT", name: "Tether", current_price: 1, price_change_24h: 0.01 },
      { id: "binancecoin", symbol: "BNB", name: "Binance Coin", current_price: 240, price_change_24h: 0.8 },
      { id: "solana", symbol: "SOL", name: "Solana", current_price: 100, price_change_24h: 2.3 },
      { id: "ripple", symbol: "XRP", name: "XRP", current_price: 0.5, price_change_24h: -1.4 },
      { id: "cardano", symbol: "ADA", name: "Cardano", current_price: 0.3, price_change_24h: 0.7 },
      { id: "dogecoin", symbol: "DOGE", name: "Dogecoin", current_price: 0.07, price_change_24h: 3.2 },
      { id: "polkadot", symbol: "DOT", name: "Polkadot", current_price: 5, price_change_24h: -0.3 },
      { id: "polygon", symbol: "MATIC", name: "Polygon", current_price: 0.5, price_change_24h: 1.1 }
    ]
  end

  def self.get_current_price(symbol, options = {})
    force_refresh = options[:force_refresh] || false
    
    # First check if we have a cached price (unless force refresh)
    unless force_refresh
      cached_price = Rails.cache.read("crypto_price:#{symbol}")
      return cached_price if cached_price.present?
    end
    
    # If force refresh or not in cache, try to get from database
    coin = Coin.find_by(symbol: symbol.upcase)
    
    # If force refresh and coin exists, fetch latest price
    if force_refresh && coin.present?
      begin
        # Try to get fresh data for this specific coin
        latest_price = fetch_latest_price_for_symbol(symbol)
        
        # Update coin if got fresh data
        if latest_price.present?
          coin.update(
            current_price: latest_price,
            last_updated: Time.current
          )
          
          # Cache the fresh price
          Rails.cache.write("crypto_price:#{symbol}", latest_price, expires_in: 2.minutes)
          return latest_price
        end
      rescue => e
        Rails.logger.error "Error refreshing price for #{symbol}: #{e.message}"
      end
    end
    
    # Use existing database price if available
    if coin&.current_price.present?
      # Cache the price from the database
      Rails.cache.write("crypto_price:#{symbol}", coin.current_price, expires_in: 2.minutes)
      return coin.current_price
    end
    
    # If not in database, fallback to static data
    fallback_coin = fallback_cryptocurrencies.find { |c| c[:symbol] == symbol.upcase }
    price = fallback_coin ? fallback_coin[:current_price] : nil
    
    # Cache the price if found
    Rails.cache.write("crypto_price:#{symbol}", price, expires_in: 2.minutes) if price.present?
    
    price
  end

  def self.fetch_latest_price_for_symbol(symbol)
    # In a real application, this would make a targeted API call for a specific coin
    # Example API endpoint: https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd
    
    begin
      # Make a simulated API call
      uri = URI("https://api.coingecko.com/api/v3/simple/price")
      params = { ids: symbol.downcase, vs_currencies: "usd" }
      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        return data[symbol.downcase]["usd"] if data[symbol.downcase].present?
      end
      
      # Fallback to the list if single coin API failed
      top_coins = fetch_top_cryptocurrencies
      coin_data = top_coins.find { |c| c[:symbol] == symbol.upcase }
      return coin_data[:current_price] if coin_data.present?
      
      nil
    rescue => e
      Rails.logger.error "Error fetching latest price for #{symbol}: #{e.message}"
      nil
    end
  end

  private

  def self.update_coins_in_database(coins_data)
    current_time = Time.current

    coins_data.each do |coin_data|
      coin = Coin.find_or_initialize_by(symbol: coin_data[:symbol])
      coin.name = coin_data[:name]
      coin.current_price = coin_data[:current_price]
      coin.last_updated = current_time
      coin.price_change_24h = coin_data[:price_change_24h] if coin_data[:price_change_24h].present?

      begin
        coin.save
      rescue => e
        Rails.logger.error "Error updating coin #{coin_data[:symbol]}: #{e.message}"
      end
    end
  end
end
