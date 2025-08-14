class StripeWebhooksController < ActionController::API
  # skip_before_action :verify_authenticity_token
  # command : stripe listen --forward-to localhost:3000/stripe/webhook
  def receive
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, secret)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error: #{e.message}"
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Signature verification failed: #{e.message}"
      return head :bad_request
    end

    begin
      case event.type
      when "checkout.session.completed"
        handle_checkout_session(event.data.object)
      when "charge.refunded"
        handle_charge_refunded(event.data.object)
      else
        Rails.logger.info "Unhandled event type: #{event.type}"
      end
    rescue => e
       Rails.logger.error "Webhook handler error for #{event.id} (#{event.type}): #{e.class} - #{e.message}"
    end

    head :ok
  end

  private
  def handle_checkout_session(session)
    payment = Payment.find_by(stripe_payment_id: session.id)

    if payment.nil?
      Rails.logger.warn "Payment not found for session #{session.id}"
      return
    end

    if payment.status == "succeeded"
      Rails.logger.info "Payment #{payment.id} already marked as succeeded"
      return
    end

    payment.update!(status: "succeeded")
    purchase = payment.purchase

    unless purchase
      begin
        Purchase.create_from_payment!(payment)
        Rails.logger.info "Purchase created for Payment #{payment.id}"
      rescue => e
        payment.update!(status: "failed")
        Rails.logger.error "Failed to create purchase in handle_checkout_session: #{e.message}"
      end
    end

    # Award points (safe to call multiple times thanks to the unique index)
    if purchase
      begin
        RewardService.award_for_purchase!(purchase)
        Rails.logger.info "Points awarded for Purchase #{purchase.id}"
      rescue => e
        Rails.logger.error "Failed to award points for Purchase #{purchase.id}: #{e.message}"
      end
    else
      Rails.logger.warn "No purchase present after creation attempt for Payment #{payment.id}"
    end
  end

  def handle_charge_refunded(charge)
    # TODO: implement refund logic as needed
  end
end
