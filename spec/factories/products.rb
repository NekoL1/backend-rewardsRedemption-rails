FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    redeem_price { 1000 }
    inventory { 10 }
  end
end 