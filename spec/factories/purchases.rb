FactoryBot.define do
  factory :purchase do
    association :user
    association :product
    association :payment

    quantity { Faker::Number.between(from: 1, to: 5) }
    original_unit_price_cents { Faker::Number.between(from: 500, to: 10_000) }
    discount_percent { Faker::Number.between(from: 0, to: 50) }
    unit_price_cents do
      (original_unit_price_cents * (100 - discount_percent) / 100.0).round
    end
    total_cents { unit_price_cents * quantity }
  end
end
