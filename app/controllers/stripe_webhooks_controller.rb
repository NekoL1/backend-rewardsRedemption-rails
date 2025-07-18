class StripeWebhooksController < ApplicationController
  # skip_before_action :verify_authenticity_token

  def receive
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, secret)
    rescue JSON::ParserError => e 
      Rails.logger.error "JSON parse error: #{e.message}"
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e 
      Rails.logger.error "Signature verification failed: #{e.message}"
      return head :bad_request
    end

    Rails.logger.info "Incoming event: #{event.type}"
    Rails.logger.info "Payload object: #{event.data.object.inspect}"

    case event.type
    when 'checkout.session.completed'  
      session = event.data.object
      Rails.logger.info "Checkout session completed: #{session.id}"

      payment = Payment.find_by(stripe_payment_id: session_id)
      if payment
        payment.update!(status: 'succeeded')
      else
        Rails.logger.warn "Payment not found for session #{session.id}"
      end
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    head :ok
  end


end