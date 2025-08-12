class User < ApplicationRecord
  has_many :redemptions, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :purchases, dependent: :destroy

  def point_balance_dollar
    (point_balance || 0) / 100.0
  end
end
