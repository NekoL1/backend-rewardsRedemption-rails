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
