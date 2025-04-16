class RefreshPortfolioPricesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting portfolio price refresh job"

    # Get all unique cryptocurrency symbols from user portfolios
    symbols = Asset.distinct.pluck(:symbol)

    if symbols.empty?
      Rails.logger.info "No cryptocurrencies to refresh"
      return
    end

    Rails.logger.info "Refreshing prices for #{symbols.count} cryptocurrencies: #{symbols.join(', ')}"

    # Refresh prices for each symbol
    success_count = 0

    symbols.each do |symbol|
      begin
        price = CryptoApi.refresh_price(symbol)
        if price.present?
          success_count += 1
          Rails.logger.info "Successfully refreshed price for #{symbol}: $#{price}"
        else
          Rails.logger.warn "Failed to get price for #{symbol}"
        end
      rescue => e
        Rails.logger.error "Error refreshing price for #{symbol}: #{e.message}"
      end
    end

    Rails.logger.info "Finished portfolio price refresh job. Successfully refreshed #{success_count}/#{symbols.count} cryptocurrencies."
  end
end
