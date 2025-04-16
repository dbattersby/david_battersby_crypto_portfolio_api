require "sidekiq"
require "sidekiq-scheduler"

# Configure Redis for Sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] || "redis://localhost:6379/0" }

  # Load the scheduler
  config.on_startup do
    # Schedule the cryptocurrency price refresh job to run every 5 minutes
    Sidekiq::Scheduler.dynamic = true
    Sidekiq.schedule = {
      "refresh_portfolio_prices" => {
        "class" => "RefreshPortfolioPricesJob",
        "cron"  => "*/5 * * * *",  # Every 5 minutes
        "queue" => "default",
        "description" => "Refresh cryptocurrency prices for portfolios every 5 minutes"
      },
      "fetch_cryptocurrency_prices" => {
        "class" => "FetchCryptocurrencyPricesJob",
        "cron"  => "*/30 * * * *",  # Every 30 minutes
        "queue" => "default",
        "description" => "Fetch all cryptocurrency prices every 30 minutes for database update"
      }
    }
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] || "redis://localhost:6379/0" }
end 