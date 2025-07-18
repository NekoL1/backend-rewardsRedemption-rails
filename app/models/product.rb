class Product < ApplicationRecord
  has_many :redemptions
  has_many :payments

  def redeem_price_dollar
    (redeem_price || 0) / 100.0
  end
end
