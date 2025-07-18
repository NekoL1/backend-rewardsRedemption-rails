class AddProductionIdAndQuantityToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :product_id, :integer
    add_column :payments, :quantity, :integer

    add_index :payments, :product_id
    add_foreign_key :payments, :products
  end
end
