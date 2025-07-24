class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :product
  # has_one :redemption
  has_one :purchase
end
