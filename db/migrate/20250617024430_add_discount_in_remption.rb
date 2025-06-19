class AddDiscountInRemption < ActiveRecord::Migration[8.0]
  def change
    add_column :redemptions, :discount, :float, default: 0.0, null: false
  end
end
