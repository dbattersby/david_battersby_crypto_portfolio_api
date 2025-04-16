# Cryptocurrency Price Database Implementation

This document explains how cryptocurrency price data is fetched, stored, and displayed in the application.

## Database Structure

The application uses a `Coin` model to store cryptocurrency price data:

```ruby
# app/models/coin.rb
class Coin < ApplicationRecord
  validates :symbol, presence: true, uniqueness: true
  validates :name, presence: true
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  before_save :upcase_symbol
end
```

## Background Job

A background job (`FetchCryptocurrencyPricesJob`) runs every minute to fetch the latest prices:

```ruby
# app/jobs/fetch_cryptocurrency_prices_job.rb
class FetchCryptocurrencyPricesJob < ApplicationJob
  queue_as :default
  
  def perform
    # Gets unique cryptocurrency symbols from assets
    symbols = Asset.distinct.pluck(:symbol)
    
    # Fetches prices from API and updates database
    crypto_data = CryptocurrencyService.fetch_top_cryptocurrencies
    
    # Updates cache for quick access
    symbols.each do |symbol|
      coin = Coin.find_by(symbol: symbol.upcase)
      if coin&.current_price.present?
        Rails.cache.write("crypto_price:#{symbol}", coin.current_price, expires_in: 2.minutes)
      end
    end
  end
end
```

## Service Layer

The `CryptocurrencyService` handles API calls and database updates:

```ruby
# app/services/cryptocurrency_service.rb
class CryptocurrencyService
  def self.fetch_top_cryptocurrencies
    # Makes API call to CoinGecko or similar
    # Updates database with fresh data
  end
  
  def self.get_current_price(symbol)
    # First check cache
    # Then check database
    # Fallback to static data if needed
  end
  
  private
  
  def self.update_coins_in_database(coins_data)
    # Updates or creates coin records
  end
end
```

## Asset Model Integration

The `Asset` model uses the database for current prices:

```ruby
# app/models/asset.rb
def current_price
  @current_price ||= begin
    db_coin = Coin.find_by(symbol: symbol.upcase)
    if db_coin&.current_price.present?
      db_coin.current_price
    else
      CryptocurrencyService.get_current_price(symbol)
    end
  end
end

def coin
  @coin ||= Coin.find_by(symbol: symbol.upcase)
end
```

## User Interface

The portfolio page displays price data with last update time:

```erb
<td>
  <strong><%= asset.name %></strong> (<%= asset.symbol %>)
  <% if asset.coin && asset.coin.last_updated %>
    <div class="price-updated">
      <small class="text-muted">Price updated: <%= time_ago_in_words(asset.coin.last_updated) %> ago</small>
    </div>
  <% end %>
</td>
```

## Technical Stack

- **Database**: PostgreSQL for storing coin data
- **Caching**: Rails cache for fast price lookups
- **Background Jobs**: Sidekiq for processing the fetch job
- **Scheduling**: Whenever gem for scheduling the job to run every 5 minutes
- **API Client**: Net::HTTP for making API calls

## Flow Diagram

1. A cron job runs every minute
2. It triggers the `FetchCryptocurrencyPricesJob`
3. The job calls `CryptocurrencyService` to fetch prices
4. The service updates the database and cache
5. When a user views their portfolio, prices come from the database
6. Last-updated timestamps show when the price was last refreshed 