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

      # broadcast inventory change
      broadcast_product_update(product)

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

  def self.broadcast_product_update(product)
    updated_product_data = product.as_json(
      only: [ :id, :name, :inventory, :redeem_price ],
      methods: [ :redeem_price_dollar ]
    )
    stream_name = "product_#{product.id}"
    Rails.logger.info("Broadcasting purchase inventory update to #{stream_name}")
    ActionCable.server.broadcast(stream_name, updated_product_data)
  end
end
