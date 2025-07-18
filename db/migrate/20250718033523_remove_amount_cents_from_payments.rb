class RemoveAmountCentsFromPayments < ActiveRecord::Migration[8.0]
  def change
    remove_column :payments, :amount_cents, :integer
  end
end
