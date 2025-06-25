class Product < ApplicationRecord
  has_many :redemptions

  def redeem_price_dollar
    (redeem_price || 0) / 100.0
  end
end
