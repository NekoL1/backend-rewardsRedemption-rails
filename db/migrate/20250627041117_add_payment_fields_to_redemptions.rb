class AddPaymentFieldsToRedemptions < ActiveRecord::Migration[8.0]
  def change
    add_reference :redemptions, :payment, foreign_key: true, null: true
    add_column :redemptions, :payment_method, :string, default: "points", null: false
  end
end
