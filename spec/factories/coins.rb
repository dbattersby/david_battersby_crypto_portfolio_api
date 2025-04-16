FactoryBot.define do
  factory :coin do
    sequence(:symbol) { |n| "BTC#{n}" }
    name { "Bitcoin" }
    current_price { 80000.0 }
    price_change_24h { 1.5 }
    last_updated { Time.current }
  end
end
