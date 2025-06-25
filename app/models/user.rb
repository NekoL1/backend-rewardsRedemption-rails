class User < ApplicationRecord
  has_many :redemptions

  def point_balance_dollar
    (point_balance || 0) / 100.0
  end
end
