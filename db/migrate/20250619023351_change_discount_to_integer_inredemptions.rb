class ChangeDiscountToIntegerInredemptions < ActiveRecord::Migration[8.0]
  def change
    change_column :redemptions, :discount, :integer, default: 0, null: false
  end
end
