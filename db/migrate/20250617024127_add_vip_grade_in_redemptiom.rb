class AddVipGradeInRedemptiom < ActiveRecord::Migration[8.0]
  def change
     add_column :redemptions, :vip_grade, :integer, default: 0, null: false
  end
end
