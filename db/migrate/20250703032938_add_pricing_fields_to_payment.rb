class AddPricingFieldsToPayment < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :original_unit_price_cents, :integer
    add_column :payments, :discounted_unit_price_cents, :integer
    add_column :payments, :discount_percent, :integer
    add_column :payments, :original_total_cents, :integer
    add_column :payments, :discounted_total_cents, :integer
  end
end
