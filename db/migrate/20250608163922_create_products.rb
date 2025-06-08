class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :redeem_price
      t.integer :inventory

      t.timestamps
    end
  end
end
