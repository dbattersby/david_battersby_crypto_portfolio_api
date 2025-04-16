class CryptoApi
  CACHE_EXPIRY = 2.minutes

  def self.get_price(symbol)
    # First try to get from cache
    cache_key = cache_key_for(symbol)
    cached_price = Rails.cache.read(cache_key)
    return cached_price if cached_price.present?

    # If not in cache, get fresh price
    price = CryptocurrencyService.get_current_price(symbol)

    # Store in cache
    Rails.cache.write(cache_key, price, expires_in: CACHE_EXPIRY) if price.present?

    price
  end

  # Fetch multiple prices at once (more efficient)
  def self.get_prices(symbols)
    return {} if symbols.blank?

    result = {}
    cache_hits = {}
    symbols_to_fetch = []

    # First check which symbols we have in cache
    symbols.each do |symbol|
      cache_key = cache_key_for(symbol)
      cached_price = Rails.cache.read(cache_key)

      if cached_price.present?
        result[symbol] = cached_price
        cache_hits[symbol] = true
      else
        symbols_to_fetch << symbol
        cache_hits[symbol] = false
      end
    end

    # Fetch missing prices if any
    if symbols_to_fetch.any?
      # Fetch all missing prices at once
      fresh_prices = {}

      # Try to get from database first
      coins = Coin.where(symbol: symbols_to_fetch.map(&:upcase))
      coins.each do |coin|
        symbol = coin.symbol.downcase
        fresh_prices[symbol] = coin.current_price if coin.current_price.present?
      end

      # For any remaining symbols, get from API or fallback data
      symbols_to_fetch.each do |symbol|
        next if fresh_prices[symbol].present?
        fresh_prices[symbol] = CryptocurrencyService.get_current_price(symbol)
      end

      # Update cache and result for fetched prices
      fresh_prices.each do |symbol, price|
        next unless price.present?
        cache_key = cache_key_for(symbol)
        Rails.cache.write(cache_key, price, expires_in: CACHE_EXPIRY)
        result[symbol] = price
      end
    end

    result
  end

  def self.refresh_price(symbol)
    price = CryptocurrencyService.get_current_price(symbol, force_refresh: true)
    cache_key = cache_key_for(symbol)
    Rails.cache.write(cache_key, price, expires_in: CACHE_EXPIRY) if price.present?
    price
  end

  def self.cache_key_for(symbol)
    "crypto_price:#{symbol.downcase}"
  end
end
