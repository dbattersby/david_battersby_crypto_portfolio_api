source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2", ">= 7.2.2.1"
# Use postgresql as the database for Active Record
gem "pg"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use SCSS for stylesheets
gem "sassc-rails"

# Authentication
gem "devise"
gem "devise-jwt"
gem "jsonapi-serializer"
gem "omniauth", "~> 2.1.1"

# API Documentation
gem "rswag-api"
gem "rswag-ui"

# Serialization
gem "active_model_serializers"

# HTTP Client for external APIs
gem "httparty"

# Background Jobs
gem "sidekiq"
gem "sidekiq-scheduler"
gem "redis"

# Caching
gem "redis-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  
  # Testing tools
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :development do
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1.0"
end

gem "importmap-rails", "~> 2.1"

gem "whenever", "~> 1.0"

gem "stimulus-rails"