class PurchasesController < ApplicationController
  # GET /purchases?user_id=:id
  def index
    user_id = params[:user_id]
    return render json: { error: "user_id is required" }, status: :bad_request if user_id.blank?

    purchases = Purchase
                  .includes(:product)
                  .where(user_id: user_id)
                  .order(created_at: :desc)

    render json: purchases.as_json(
      include: { product: { only: %i[id name] } },
      except:  %i[updated_at]
    )
  end

  # GET /purchases/show_by_payment?payment_id=:id
  def show_by_payment
    payment = Payment.find_by(id: params[:payment_id])
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

  # POST /purchases/start_stripe_payment
  def start_stripe_payment
    user     = User.find_by(id: params[:user_id])
    product  = Product.find_by(id: params[:product_id])
    quantity = quantity_param

    return render_unprocessable("User not found")    unless user
    return render_unprocessable("Product not found") unless product
    return render_unprocessable("Quantity must be at least 1") if quantity < 1
    return render_unprocessable("Not enough inventory")         if product.inventory < quantity

    # NOTE: This expects product.redeem_price to be in integer cents.
    # If it's dollars/decimal, convert before calling (e.g., (price * 100).round).
    pricing = calculate_pricing_cents(product.redeem_price, quantity, user.vip_grade)

    payment = create_payment_record!(user, product, quantity, pricing)

    session = build_checkout_session!(
      payment:  payment,
      product:  product,
      quantity: quantity,
      pricing:  pricing
    )

    payment.update!(stripe_payment_id: session.id)

    render json: { stripe_url: session.url, payment_id: payment.id }
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error in start_stripe_payment: #{e.class}: #{e.message}"
    render json: { error: "Payment failed to initiate with Stripe" }, status: :bad_gateway
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Record invalid in start_stripe_payment: #{e.record.class} #{e.record.errors.full_messages.join(', ')}"
    render json: { error: "Payment could not be created" }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Error in start_stripe_payment: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Payment failed to initiate" }, status: :internal_server_error
  end

  private

  # Calculates pricing in **integer cents** and clamps discount to [0, 100].
  # Assumes `unit_price_cents` is an integer number of cents.
  def calculate_pricing_cents(unit_price_cents, quantity, vip_grade)
    unit_price_cents = Integer(unit_price_cents)
    quantity         = Integer(quantity)

    discount_percent = (vip_grade.to_i * 10).clamp(0, 100)
    # Keep the math in cents and round once to avoid float drift.
    discounted_unit_price_cents = (unit_price_cents * (100 - discount_percent) / 100.0).round

    {
      original_unit_price_cents:   unit_price_cents,
      discounted_unit_price_cents: discounted_unit_price_cents,
      original_total_cents:        unit_price_cents * quantity,
      discounted_total_cents:      discounted_unit_price_cents * quantity,
      discount_percent:            discount_percent
    }
  end

  def create_payment_record!(user, product, quantity, pricing)
    Payment.create!(
      user:                          user,
      product_id:                    product.id,
      quantity:                      quantity,
      original_unit_price_cents:     pricing[:original_unit_price_cents],
      discounted_unit_price_cents:   pricing[:discounted_unit_price_cents],
      discount_percent:              pricing[:discount_percent],
      original_total_cents:          pricing[:original_total_cents],
      discounted_total_cents:        pricing[:discounted_total_cents],
      currency:                      "cad",
      status:                        "pending"
    )
  end

  def build_checkout_session!(payment:, product:, quantity:, pricing:)
    frontend_url = ENV["FRONTEND_URL"].to_s
    raise "FRONTEND_URL not configured" if frontend_url.blank?

    Stripe::Checkout::Session.create(
      # Consider: automatic_payment_methods: { enabled: true }
      payment_method_types: [ "card" ],
      line_items: [
        {
          price_data: {
            currency:    payment.currency,
            product_data: { name: product.name },
            # Stripe requires integer cents
            unit_amount: payment.discounted_unit_price_cents
          },
          quantity: quantity
        }
      ],
      mode:        "payment",
      success_url: "#{frontend_url}/payment/payment-success?session_id={CHECKOUT_SESSION_ID}&payment_id=#{payment.id}",
      cancel_url:  "#{frontend_url}/payment/payment-cancel",
      metadata: {
        payment_id:                  payment.id,
        user_id:                     payment.user_id,
        product_id:                  product.id,
        quantity:                    quantity,
        original_unit_price_cents:   pricing[:original_unit_price_cents],
        discounted_unit_price_cents: pricing[:discounted_unit_price_cents],
        discount_percent:            pricing[:discount_percent]
      }
    )
  end

  def quantity_param
    Integer(params[:quantity])
  rescue ArgumentError, TypeError
    0
  end

  def render_unprocessable(message)
    render json: { error: message }, status: :unprocessable_entity
  end
end
