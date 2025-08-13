FactoryBot.define do
  factory :reward_transaction do
    user { nil }
    purchase { nil }
    points { 1 }
    kind { "MyString" }
    amount_cents { 1 }
  end
end
