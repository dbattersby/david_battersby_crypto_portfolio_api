FactoryBot.define do
  factory :asset do
    user
    sequence(:symbol) { |n| "BTC#{n}" }
    name { "Bitcoin" }
    quantity { 1.0 }
    purchase_price { 20000.0 }
  end
end
