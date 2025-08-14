class RewardService
  POINT_RATE = 1       # 100% of paid amount for reward
  CENTS_PER_POINT = 100   # 100 cents = 1 point

  # Award points for a completed purchase.
  def self.award_for_purchase!(purchase)
    amount_cents = purchase.total_cents || 0
    return if amount_cents <= 0

    points = (amount_cents * POINT_RATE).floor
    return if points <= 0

    RewardTransaction.create!(
      user_id: purchase.user_id,
      purchase_id: purchase.id,
      kind: "earn",
      points: points,
      amount_cents: amount_cents
    )

    increment_user_points(purchase.user_id, points)
  rescue ActiveRecord::RecordNotUnique
    nil  # Duplicate webhook delivery (earn already created) → ignore
  end



  # Reverse all points earned by this purchase (full refund/chargeback).
  def self.reverse_all_for_purchase(purchase)
    original = RewardTransaction.find_by(purchase_id: purchase.id, kind: "earn")
    return unless original

    RewardTransaction.create!(
      user_id: purchase.user_id,
      purchase_id: purchase.id,
      kind: "reversal",
      points: -original.points,
      amount_cents: original.amount_cents
    )

    increment_user_points(purchase.user_id, (-original.points))
  end


  # Helper: find purchase by Stripe Payment Intent ID.
  def self.find_purchase_by_payment_intent(payment_intent_id)
    return nil if payment_intent_id.blank?

    Purchase.joins(:payment).find_by(payments: { stripe_payment_id: payment_intent_id })
  end


  # Update users.point_balance safely (coalesce nil to 0), no callbacks needed here.
  def self.increment_user_points(user_id, delta)
    user = User.find(user_id)
    user.update!(point_balance: user.point_balance + delta, updated_at: Time.current)
  end
end
