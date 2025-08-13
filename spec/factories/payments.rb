FactoryBot.define do
  factory :payment do
    association :user
    association :product

    currency { %w[cad usd].sample }
    status { %w[pending succeeded failed].sample }
    stripe_payment_id { Faker::Finance.credit_card(:visa).delete(" ") }

    original_unit_price_cents { Faker::Number.between(from: 500, to: 10_000) }
    discount_percent { Faker::Number.between(from: 0, to: 50) }
    discounted_unit_price_cents do
      (original_unit_price_cents * (100 - discount_percent) / 100.0).round
    end
    original_total_cents { original_unit_price_cents * quantity }
    discounted_total_cents { discounted_unit_price_cents * quantity }
    quantity { Faker::Number.between(from: 1, to: 5) }
  end
end
