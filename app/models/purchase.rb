class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :payment

  def self.create_from_payment!(payment)
    raise "Purchase already exists for payment #{payment.id}" if payment.purchase.present?

    product = payment.product
    user = payment.user
    quantity = payment.quantity

    raise "Not enough inventory" if product.inventory < quantity

    unit_price = payment.discounted_unit_price_cents
    total_price = unit_price * quantity

    Purchase.transaction do
      # Lock and update inventory
      product.lock!
      product.update!(inventory: product.inventory - quantity)

      # Create purchase record
      create!(
        user: user,
        product: product,
        quantity: quantity,
        payment: payment,
        original_unit_price_cents: payment.original_unit_price_cents,
        discount_percent: payment.discount_percent,
        unit_price_cents: unit_price,
        total_cents: total_price
      )
    end
  end
end
