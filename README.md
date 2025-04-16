# Crypto Portfolio API

A comprehensive cryptocurrency portfolio management application that allows users to track their crypto assets, record transactions, and monitor portfolio performance over time.

## Technology Stack

- **Ruby**: 3.3.6
- **Rails**: 7.2.2
- **Database**: PostgreSQL
- **Authentication**: Devise & JWT for API authentication
- **Background Processing**: Sidekiq with Redis
- **JavaScript**: Sprockets Asset Pipeline
- **API Documentation**: Rswag
- **Testing**: RSpec, Factory Bot, Shoulda Matchers

## Features

- User authentication with Devise
- Cryptocurrency portfolio management
- Transaction recording (buy/sell)
- Real-time price updates from CoinGecko
- Portfolio valuation and performance tracking
- API endpoints for mobile integration

## Getting Started

### Prerequisites

- Ruby 3.3.6
- PostgreSQL
- Redis (for Sidekiq)
- Node.js and Yarn

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd rails-crypto-portfolio-api
```

2. Install dependencies
```bash
bundle install
```

3. Setup the database
```bash
rails db:create
rails db:migrate
rails db:seed # if seed data is available
```

4. Start the Redis server
```bash
redis-server
```

5. Start Sidekiq for background jobs
```bash
bundle exec sidekiq
```

6. Start the Rails server
```bash
rails server
```

The application will be available at `http://localhost:3000`.

## Usage

### Managing Your Portfolio

1. Sign up for an account
2. Add assets to your portfolio
3. Record buy and sell transactions
4. View portfolio performance and transaction history

### API Endpoints

The application provides a RESTful API for integration with mobile apps or other services:

- **Authentication**
  - POST `/api/v1/auth/signup`: Create a new user account
  - POST `/api/v1/auth/login`: Authenticate and get JWT token
  - POST `/api/v1/auth/logout`: Invalidate token

- **Assets**
  - GET `/api/v1/assets`: List all user assets
  - GET `/api/v1/assets/:id`: Get specific asset details
  - POST `/api/v1/assets`: Create a new asset
  - PUT `/api/v1/assets/:id`: Update an asset
  - DELETE `/api/v1/assets/:id`: Remove an asset

- **Transactions**
  - GET `/api/v1/transactions`: List all transactions
  - GET `/api/v1/transactions/:id`: Get transaction details
  - POST `/api/v1/transactions`: Create a transaction

## Development

### Running Tests

```bash
bundle exec rspec
```

### Background Jobs

The application uses Sidekiq for background processing, particularly for cryptocurrency price updates. To set up scheduled jobs:

1. Make sure Redis is running
2. Start Sidekiq: `bundle exec sidekiq`
3. Check the scheduled jobs in `config/sidekiq.yml`

## Deployment

The application is designed to be deployed to platforms like Heroku or AWS:

1. Set up the required environment variables
2. Configure the production database
3. Set up Redis for production
4. Configure Sidekiq for production

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- CoinGecko API for cryptocurrency price data
- All the open-source contributors whose libraries made this project possible
