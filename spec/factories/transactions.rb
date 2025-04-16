FactoryBot.define do
  factory :transaction do
    user
    asset
    transaction_type { "buy" }
    quantity { 1.0 }
    price { 20000.0 }

    trait :buy do
      transaction_type { "buy" }
    end

    trait :sell do
      transaction_type { "sell" }
    end
  end
end
