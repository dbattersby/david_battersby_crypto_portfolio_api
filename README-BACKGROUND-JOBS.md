# Background Jobs for Cryptocurrency Price Updates

This application uses background jobs to fetch cryptocurrency prices every minute, ensuring that your portfolio displays the most up-to-date values without slowing down the application.

## How It Works

1. **Scheduled Job**: A job runs every minute to fetch the latest cryptocurrency prices from an external API.
2. **Caching**: Prices are stored in the Rails cache with a 2-minute expiration time.
3. **Asset Model**: When displaying prices in the UI, the Asset model retrieves prices from the cache instead of making direct API calls.

## Setup Instructions

### 1. Install Redis

Background jobs require Redis:

```bash
# macOS
brew install redis
brew services start redis

# Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl start redis-server
```

### 2. Start Sidekiq

Run Sidekiq to process background jobs:

```bash
bundle exec sidekiq
```

### 3. Setup Cron Jobs (Optional for Development)

For production environments, you'll need to set up the cron schedule:

```bash
# Update crontab with the schedule
bundle exec whenever --update-crontab

# Check if it's set up correctly
crontab -l
```

## Monitor Jobs

The Sidekiq Web UI is available at `/sidekiq` in development mode.

## Implementation Details

- `FetchCryptocurrencyPricesJob`: Fetches prices and stores them in the cache
- `CryptocurrencyService`: Provides methods to fetch prices from the API and retrieve from cache
- Configuration: Sidekiq is configured in `config/initializers/sidekiq.rb`
- Schedule: Defined in `config/schedule.rb` using the whenever gem

## Troubleshooting

- Check Redis is running: `redis-cli ping` (should return "PONG")
- Check Sidekiq logs: `log/sidekiq.log`
- Check cron logs: `log/cron.log` 