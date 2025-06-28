class User < ApplicationRecord
  has_many :redemptions
  has_many :payments

  def point_balance_dollar
    (point_balance || 0) / 100.0
  end
end
