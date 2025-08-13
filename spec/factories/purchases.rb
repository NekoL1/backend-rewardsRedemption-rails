FactoryBot.define do
  factory :purchase do
    association :user
    association :product
    association :payment

    quantity { 1 }
    original_unit_price_cents { 1000 }
    discount_percent { 10 }
    unit_price_cents { 900 }
    total_cents { 900 }
  end
end 
