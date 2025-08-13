FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    email { Faker::Internet.unique.email }
    point_balance { Faker::Number.between(from: 0, to: 100_000) }
    vip_grade { Faker::Number.between(from: 0, to: 5) }
  end
end
