class FetchCryptocurrencyPricesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Fetching cryptocurrency prices..."

    # Get all unique cryptocurrency symbols from assets
    symbols = Asset.distinct.pluck(:symbol)

    # Skip if no assets
    if symbols.empty?
      Rails.logger.info "No cryptocurrencies to fetch prices for."
      return
    end

    Rails.logger.info "Fetching prices for: #{symbols.join(', ')}"

    # Fetch prices from the API and store in the database
    begin
      # Fetch all prices in one API call
      CryptocurrencyService.fetch_top_cryptocurrencies

      # This will automatically update the database through the service

      # Count how many symbols we successfully updated
      updated_symbols = symbols.select do |symbol|
        coin = Coin.find_by(symbol: symbol.upcase)
        coin&.current_price.present?
      end

      Rails.logger.info "Successfully updated prices for #{updated_symbols.count}/#{symbols.count} cryptocurrencies in the database."

      # Also update the cache for quick access
      symbols.each do |symbol|
        coin = Coin.find_by(symbol: symbol.upcase)
        if coin&.current_price.present?
          Rails.logger.info "Updating cache for #{symbol}: #{coin.current_price}"
          Rails.cache.write("crypto_price:#{symbol}", coin.current_price, expires_in: 2.minutes)

          # Also cache price change data if available
          if coin.price_change_24h.present?
            Rails.logger.info "Updating 24h change cache for #{symbol}: #{coin.price_change_24h}%"
            Rails.cache.write("crypto_price_change_24h:#{symbol}", coin.price_change_24h, expires_in: 2.minutes)
          end
        end
      end
    rescue => e
      Rails.logger.error "Error in cryptocurrency price job: #{e.message}"
    end
  end
end
