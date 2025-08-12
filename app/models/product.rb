class Product < ApplicationRecord
  has_many :redemptions, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :purchases, dependent: :destroy

  def redeem_price_dollar
    (redeem_price || 0) / 100.0
  end
end
