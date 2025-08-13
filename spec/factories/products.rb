FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    redeem_price { Faker::Number.between(from: 100, to: 10_000) }
    inventory { Faker::Number.between(from: 0, to: 500) }
  end
end
