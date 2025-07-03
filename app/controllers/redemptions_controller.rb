class RedemptionsController < ApplicationController
  before_action :set_redemption, only: %i[ show update destroy ]

  # GET /redemptions
  def index
    @redemptions = Redemption.all

    render json: @redemptions
  end

  # GET /redemptions/1
  def show
    render json: @redemption
  end

  # POST /redemptions
  def create
    @redemption = Redemption.new(redemption_params)

    if @redemption.save
      render json: @redemption, status: :created, location: @redemption
    else
      render json: @redemption.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /redemptions/1
  def update
    if @redemption.update(redemption_params)
      render json: @redemption
    else
      render json: @redemption.errors, status: :unprocessable_entity
    end
  end

  # DELETE /redemptions/1
  def destroy
    @redemption.destroy!
  end


  def redeem_with_points
    user = User.find(params[:user_id])
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    raw_discount = user.vip_grade * 10
    discount = raw_discount / 100.0  # get a decimal discount, not an intege

    if product.inventory < quantity
      return render json: { error: "Not enough inventory" }, status: :unprocessable_entity
    end

    Product.transaction do
      product.lock!

      if product.inventory < quantity
        return render json: { error: "Not enough inventory" }, status: :unprocessable_entity
      end

      total_cost = product.redeem_price * quantity * (1 - discount)
      total_cost = total_cost.round
      if user.point_balance < total_cost
        return render json: { error: "Not enough points" }, status: :unprocessable_entity
      end

      # Update product inventory & user point balance
      product.update!(inventory: product.inventory - quantity)
      user.update!(point_balance: user.point_balance - total_cost)

      # Create the redemption record
      redemption = Redemption.create!(
        user: user,
        product: product,
        quantity: quantity,
        redeem_price: product.redeem_price,
        redeem_points: total_cost,
        vip_grade: user.vip_grade,
        discount: raw_discount,
        payment_method: "points"
      )
      render json: { message: "Redemption successful!", redemption: redemption }, status: :created
    end
  rescue ActiveRecord::RecordNotFound
    render json:  { error: "User or product not found" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def start_stripe_payment
    user=User.find(params[:user_id])
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    discount_percent  = user.vip_grade * 10
    discount = discount_percent / 100.0

    original_unit_price = product.redeem_price
    discounted_unit_price = original_unit_price * quantity * (1 - discount)
    original_total_cost = original_unit_price * quantity
    discounted_total_cost = discounted_unit_price * quantity

    if product.inventory < quantity
      return render json: { error: "Not enough inventory" }, status: :unprocessable_entity
    end

    payment = Payment.create!(
      user: user,
      original_unit_price_cents: original_unit_price,
      discounted_unit_price_cents: discounted_unit_price,
      discount_percent: discount_percent,
      amount_cents: total_cost,
      original_total_cents: original_total_cost,
      discounted_total_cents: discounted_total_cost,
      currency: "cad",
      status: "pending",
    )

    # 1. Create a Stripe Checkout Session
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
      success_url: "#{ENV['FRONTEND_URL']}/payment-success?session_id={CHECKOUT_SESSION_ID}&payment_id=#{payment.id}",
      cancel_url: "#{ENV['FRONTEND_URL']}/payment-cancel",
      metadata: {
        payment_id: payment.id,
        user_id: user.id,
        product_id: product.id,
        original_unit_price: original_unit_price,
        discount_percent: discount_percent,
        discounted_unit_price: discounted_unit_price
      }
    )

    payment.update!(stripe_payment_id: session.id)
    render json: { stripe_url: session.url, payment_id: payment.id }
  end



  def user_history
    user = User.find(params[:id])
    redemptions = user.redemptions
                      .includes(:product)
                      .order(created_at: :desc)
    render json: redemptions.as_json(
      only: [ :id, :quantity, :created_at, :vip_grade, :discount ],
      methods: [ :redeem_price_dollar, :redeem_points_dollar ],
      include: {
        product: {
          only: [ :id, :name, :redeem_price ],
          methods: [ :redeem_price_dollar ]
        }
      }
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_redemption
      @redemption = Redemption.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def redemption_params
      params.expect(redemption: [ :user_id, :product_id, :quantity, :redeem_price, :redeem_points ])
    end
end
