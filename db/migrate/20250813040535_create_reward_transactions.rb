class CreateRewardTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reward_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :purchase, foreign_key: true     # link to purchase for earn & reversal
      t.integer :points, null: false                # + for earn, - for reversal/spend
      t.integer :amount_cents                       # amount that generated these points
      t.string :kind, null: false                   # "earn", "spend", "reversal", "adjustment"
      t.timestamps
    end

    add_index :reward_transactions, :kind
    add_index :reward_transactions, [ :purchase_id, :kind ], unique: true, where: "kind = 'earn'"
  end
end
