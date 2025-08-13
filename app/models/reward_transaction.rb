class RewardTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :purchase, optional: true
end
