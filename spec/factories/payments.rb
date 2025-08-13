FactoryBot.define do
  factory :payment do
    association :user
    association :product

    currency { "cad" }
    status { "pending" }
    stripe_payment_id { nil }

    original_unit_price_cents { 1000 }
    discounted_unit_price_cents { 900 }
    discount_percent { 10 }
    original_total_cents { 1000 }
    discounted_total_cents { 900 }
    quantity { 1 }
  end
end 