class StripeController < ApplicationController
  # skip_before_action :verify_authenticity_token

  def webhook
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error("Stripe webhook error: #{e.message}")
      return head :bad_request
    end

    if event["type"] == "checkout.session.completed"
      session = event["data"]["object"]
      handle_checkout_session(session)
      Rails.logger.info("Received checkout.session.completed event!")
    end
    # Rails.logger.info("Received event: #{event['type']}")
    head :ok
  end


  private
  def handle_checkout_session(session)
    # This is where you find your Payment by session['id'],
    # check if already fulfilled, and create Redemption if needed.

    stripe_session_id = session["id"]
    Rails.logger.info "Handling session completed for: #{stripe_session_id}"

    payment = Payment.find_by(stripe_payment_id: stripe_session_id)

    if payment.nil?
      Rails.logger.error "No payment found for stripe_payment_id=#{stripe_session_id}"
      return head :not_found
    end

    payment.update!(status: "succeeded")
    Rails.logger.info "Payment #{payment.id} marked as succeeded"

    # You must store product_id and quantity in Payment or in session['metadata']
    # Example if you store in Payment:
    product = Product.find(payment.product_id)
    user = payment.user
    quantity = payment.quantity

    if product.inventory >= quantity

      Product.transaction do
        product.lock!
        product.update!(inventory: product.inventory - quantity)

        Redemption.create!(
          user: user,
          product: product,
          quantity: quantity,
          redeem_price: product.redeem_price,
          redeem_points: payment.amount_cents,
          payment_method: "money",
          payment: payment
        )

        Rails.logger.info "Redemption created for Payment #{payment.id}"
      end
    else
      payment.update!(status: "failed")
      Rails.logger.warn "Not enough inventory for Payment #{payment.id}"
    end
  end
end
