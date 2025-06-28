class Redemption < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :payment
  def redeem_price_dollar
    (redeem_price || 0) / 100.0
  end

  def redeem_points_dollar
    (redeem_points || 0) / 100.0
  end
end
