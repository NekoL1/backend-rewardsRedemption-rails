FactoryBot.define do
  factory :reward_transaction do
    association :user
    association :purchase
    points { Faker::Number.between(from: 10, to: 5_000) }
    kind { %w[earn redeem adjustment].sample }
    amount_cents { Faker::Number.between(from: 100, to: 50_000) }
  end
end
