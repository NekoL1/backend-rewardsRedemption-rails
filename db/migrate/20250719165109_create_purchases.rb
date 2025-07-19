class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.integer :quantity
      t.integer :original_unit_price_cents
      t.integer :discount_percent
      t.integer :unit_price_cents
      t.integer :total_cents

      t.timestamps
    end
  end
end
