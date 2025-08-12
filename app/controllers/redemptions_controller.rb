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

    validate_redemption(user, product, quantity)

    Product.transaction do
      perform_redemption(user, product, quantity)
    end
    render json: { message: "Redemption successful!", redemption: redemption }, status: :created
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

    def validate_redemption(user, product, quantity)
      if product.inventory < quantity
        raise "Not enough inventory"
      end

      total_cost = calculate_total_cost(user, product, quantity)
      if user.point_balance < total_cost
        raise "Not enough points"
      end
    end

    def calculate_total_cost(user, product, quantity)
      discount_percentage = user.vip_grade * 10
      discounted_price = product.redeem_price * (100 - discount_percentage) / 100.0
      (discounted_price * quantity).round
    end

    def perform_redemption(user, product, quantity)
      product.lock!
      validate_redemption(user, product, quantity) # Double-check after lock

      total_cost = calculate_total_cost(user, product, quantity)

      # update and broadcast product
      product.update!(inventory: product.inventory - quantity)
      broadcast_product_update(product)

      # update and broadcast user
      user.update!(point_balance: user.point_balance - total_cost)
      broadcast_user_update(user)

      # create new redemption record
      create_redemption(user, product, quantity, total_cost)
    end

    def broadcast_product_update(product)
      updated_product_data = product.as_json(
        only: [ :id, :name, :inventory, :redeem_price ],
        methods: [ :redeem_price_dollar ]
      )
      Rails.logger.info("Broadcasting to product_#{product.id}: #{updated_product_data.inspect}")
      stream_name = "product_#{product.id}"
      Rails.logger.info("Broadcasting to #{stream_name}")
      ActionCable.server.broadcast("product_#{product.id}", updated_product_data)
    end

    def broadcast_user_update(user)
      user_data = user.as_json(
        only: [ :id, :name, :phone, :email, :vip_grade, :created_at, :updated_at ],
        methods: [ :point_balance_dollar ]
      )
      ActionCable.server.broadcast("user_#{user.id}", user_data)
    end

    def create_redemption(user, product, quantity, total_cost)
      @redemption = Redemption.create!(
        user: user,
        product: product,
        quantity: quantity,
        redeem_price: product.redeem_price,
        redeem_points: total_cost,
        vip_grade: user.vip_grade,
        discount: user.vip_grade * 10,
        payment_method: "points"
      )
      broadcast_redemption_update(@redemption)
      @redemption
    end

    def broadcast_redemption_update(redemption)
      redemption_data = redemption.as_json(
        only: [ :id, :quantity, :created_at, :vip_grade, :discount ],
        methods: [ :redeem_price_dollar, :redeem_points_dollar ],
        include: {
          product: {
            only: [ :id, :name, :redeem_price ],
            methods: [ :redeem_price_dollar ]
          }
        }
      )
      ActionCable.server.broadcast("redemption_user_#{redemption.user.id}", redemption_data)
    end
end
