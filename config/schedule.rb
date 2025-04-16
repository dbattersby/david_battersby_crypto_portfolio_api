# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Set the environment
set :environment, ENV["RAILS_ENV"] || "development"
set :output, "#{path}/log/cron.log"

# Use bundle exec to ensure the correct environment
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"
job_type :runner, "cd :path && :environment_variable=:environment bundle exec rails runner :task :output"
job_type :sidekiq, "cd :path && RAILS_ENV=:environment bundle exec sidekiq-client push :task :output"

# NOTE: Cryptocurrency price updates are now configured in config/initializers/sidekiq.rb
# using sidekiq-scheduler to avoid duplication and ensure consistent scheduling
#
# every 1.minute do
#   runner "FetchCryptocurrencyPricesJob.perform_later"
# end

# Learn more: http://github.com/javan/whenever
