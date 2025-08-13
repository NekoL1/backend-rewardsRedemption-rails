# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

puts "Seeding data..."

# Create or find demo users
10.times do
  User.find_or_create_by!(email: Faker::Internet.unique.email) do |user|
    user.name = Faker::Name.name
    user.phone = Faker::PhoneNumber.cell_phone_in_e164
    user.point_balance = Faker::Number.between(from: 0, to: 200_000)
    user.vip_grade = Faker::Number.between(from: 0, to: 5)
  end
end

# Create or find products
15.times do
  Product.find_or_create_by!(name: Faker::Commerce.unique.product_name) do |product|
    product.redeem_price = Faker::Number.between(from: 200, to: 20_000)
    product.inventory = Faker::Number.between(from: 0, to: 500)
  end
end

users = User.all.to_a
products = Product.all.to_a

# Create some payments and purchases
20.times do
  user = users.sample
  product = products.sample
  quantity = Faker::Number.between(from: 1, to: 3)
  original_unit_price_cents = Faker::Number.between(from: 500, to: 10_000)
  discount_percent = Faker::Number.between(from: 0, to: 50)
  discounted_unit_price_cents = (original_unit_price_cents * (100 - discount_percent) / 100.0).round

  payment = Payment.create!(
    user: user,
    product: product,
    currency: %w[cad usd].sample,
    status: %w[pending succeeded failed].sample,
    stripe_payment_id: SecureRandom.hex(8),
    original_unit_price_cents: original_unit_price_cents,
    discounted_unit_price_cents: discounted_unit_price_cents,
    discount_percent: discount_percent,
    original_total_cents: original_unit_price_cents * quantity,
    discounted_total_cents: discounted_unit_price_cents * quantity,
    quantity: quantity
  )

  Purchase.create!(
    user: user,
    product: product,
    payment: payment,
    quantity: quantity,
    original_unit_price_cents: original_unit_price_cents,
    discount_percent: discount_percent,
    unit_price_cents: discounted_unit_price_cents,
    total_cents: discounted_unit_price_cents * quantity
  )
end

puts "Seeding complete. Users: #{User.count}, Products: #{Product.count}, Purchases: #{Purchase.count}"
