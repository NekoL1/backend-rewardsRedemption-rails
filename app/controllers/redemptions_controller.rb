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

      # Broadcast the updated user info
      # Sends real-time user data to any client subscribed to "user_#{user.id}"
      ActionCable.server.broadcast(
        "user_#{user.id}",
        user.as_json(
          only: [ :id, :name, :phone, :email, :vip_grade, :created_at, :updated_at ],
          methods: [ :point_balance_dollar ]
        )
      )

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
