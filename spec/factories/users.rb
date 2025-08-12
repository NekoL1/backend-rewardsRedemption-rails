FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:phone) { |n| "555-000#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    point_balance { 0 }
    vip_grade { 0 }
  end
end 