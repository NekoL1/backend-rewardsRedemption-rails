class PurchasesController < ApplicationController
  def index
    user_id  = params[:user_id]

    if user_id.blank?
      return render json: { error: "user_id is required" }, status: :bad_request
    end
    purchases = Purchase.includes(:product)
                    .where(user_id: user_id)
                    .order(created_at: :desc)
    render json: purchases.as_json(include: {
      product: { only: [ :id, :name ] }
    }, except: [ :updated_at ])
  end

  def show_by_payment
    payment_id = params[:payment_id]
    payment = Payment.find_by(id: payment_id)
    return render json: { error: "Payment not found" }, status: :not_found unless payment

    purchase = Purchase.find_by(payment_id: payment.id)
    return render json: { error: "Purchase not found" }, status: :not_found unless purchase

    render json: {
      product_name: purchase.product.name,
      quantity: purchase.quantity,
      total_paid_cents: purchase.total_cents,
      currency: payment.currency,
      user_email: payment.user.email,
      disouct: payment.discount_percent
    }
  end

  def start_stripe_payment
    user = User.find(params[:user_id])
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    discount_percent = user.vip_grade * 10
    discount = discount_percent / 100.0

    original_unit_price = product.redeem_price
    discounted_unit_price = original_unit_price * (1 - discount)
    original_total_cost = original_unit_price * quantity
    discounted_total_cost = discounted_unit_price * quantity

    if product.inventory < quantity
      return render json: { error: "Not enough inventory" }, status: :unprocessable_entity
    end

    payment = Payment.create!(
      user: user,
      product_id: product.id,
      quantity: quantity,
      original_unit_price_cents: original_unit_price,
      discounted_unit_price_cents: discounted_unit_price,
      discount_percent: discount_percent,
      original_total_cents: original_total_cost,
      discounted_total_cents: discounted_total_cost,
      currency: "cad",
      status: "pending"
    )

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [ {
        price_data: {
          currency: payment.currency,
          product_data: { name: product.name },
          unit_amount: payment.discounted_unit_price_cents
        },
        quantity: quantity
      } ],
      mode: "payment",
      success_url: "#{ENV['FRONTEND_URL']}/payment/payment-success?session_id={CHECKOUT_SESSION_ID}&payment_id=#{payment.id}",
      cancel_url: "#{ENV['FRONTEND_URL']}/payment/payment-cancel",
      metadata: {
        payment_id: payment.id,
        user_id: user.id,
        product_id: product.id,
        quantity: quantity,
        original_unit_price: original_unit_price,
        discount_percent: discount_percent,
        discounted_unit_price: discounted_unit_price
      }
    )

    payment.update!(stripe_payment_id: session.id)

    render json: { stripe_url: session.url, payment_id: payment.id }
    rescue => e
      Rails.logger.error "Error in start_stripe_payment: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Payment failed to initiate" }, status: :internal_server_error
  end
end
