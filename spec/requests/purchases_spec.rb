require "rails_helper"

RSpec.describe "Purchases", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "GET /purchases" do
    let(:user) { create(:user) }
    let!(:product) { create(:product, name: "Gold", redeem_price: 1500, inventory: 5) }
    let!(:payment) { create(:payment, user: user, product: product, quantity: 2) }
    let!(:purchase) { create(:purchase, user: user, product: product, payment: payment, quantity: 2, unit_price_cents: payment.discounted_unit_price_cents, total_cents: payment.discounted_unit_price_cents * 2) }

    it "requires user_id" do
      get "/purchases"
      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("user_id is required")
    end

    it "returns purchases for the user including product info" do
      get "/purchases", params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      item = body.first
      expect(item).to include(
        "id" => purchase.id,
        "user_id" => user.id,
        "product_id" => product.id,
        "payment_id" => payment.id,
        "quantity" => 2,
        "unit_price_cents" => payment.discounted_unit_price_cents,
        "total_cents" => payment.discounted_unit_price_cents * 2,
        "created_at" => be_present
      )
      expect(item).not_to have_key("updated_at")
      expect(item["product"]).to include(
        "id" => product.id,
        "name" => product.name
      )
    end
  end

  describe "GET /purchases/:payment_id" do
    let(:user) { create(:user, email: "buyer@example.com") }
    let!(:product) { create(:product, name: "Silver", redeem_price: 2000, inventory: 5) }
    let!(:payment) { create(:payment, user: user, product: product, currency: "cad", discount_percent: 20, discounted_unit_price_cents: 1600, original_unit_price_cents: 2000) }
    let!(:purchase) { create(:purchase, user: user, product: product, payment: payment, quantity: 3, unit_price_cents: 1600, total_cents: 4800) }

    it "returns not found when payment missing" do
      get "/purchases/999999"
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include("error" => "Payment not found")
    end

    it "returns not found when purchase missing" do
      other_payment = create(:payment)
      get "/purchases/#{other_payment.id}"
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include("error" => "Purchase not found")
    end

    it "returns purchase details by payment id" do
      get "/purchases/#{payment.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        "product_name" => product.name,
        "quantity" => 3,
        "total_paid_cents" => 4800,
        "currency" => "cad",
        "user_email" => "buyer@example.com",
        "disouct" => 20
      )
    end
  end

  describe "POST /purchases/start_stripe_payment" do
    let(:user) { create(:user, vip_grade: 2) } # -> 20% discount
    let(:product) { create(:product, redeem_price: 5000, inventory: 3) }

    before do
      # Ensure FRONTEND_URL is present
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("FRONTEND_URL").and_return("https://frontend.test")

      # Stub Stripe::Checkout::Session.create
      allow(Stripe::Checkout::Session).to receive(:create).and_return(
        double("Session", id: "sess_123", url: "https://stripe.test/checkout/sess_123")
      )
    end

    it "returns 422 for missing user" do
      post "/purchases/start_stripe_payment", params: { user_id: 0, product_id: product.id, quantity: 1 }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => "User not found")
    end

    it "returns 422 for missing product" do
      post "/purchases/start_stripe_payment", params: { user_id: user.id, product_id: 0, quantity: 1 }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => "Product not found")
    end

    it "returns 422 for invalid quantity" do
      post "/purchases/start_stripe_payment", params: { user_id: user.id, product_id: product.id, quantity: 0 }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => "Quantity must be at least 1")
    end

    it "returns 422 for insufficient inventory" do
      post "/purchases/start_stripe_payment", params: { user_id: user.id, product_id: product.id, quantity: 10 }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error" => "Not enough inventory")
    end

    it "creates a Payment and returns Stripe checkout url with payment id" do
      expect do
        post "/purchases/start_stripe_payment", params: { user_id: user.id, product_id: product.id, quantity: 2 }
      end.to change(Payment, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("stripe_url" => "https://stripe.test/checkout/sess_123")
      expect(body).to have_key("payment_id")

      payment = Payment.find(body["payment_id"])
      expect(payment.user_id).to eq(user.id)
      expect(payment.product_id).to eq(product.id)
      expect(payment.quantity).to eq(2)

      # vip_grade = 2 => 20% discount; unit price 5000 -> 4000
      expect(payment.discount_percent).to eq(20)
      expect(payment.discounted_unit_price_cents).to eq(4000)
      expect(payment.original_total_cents).to eq(10000)
      expect(payment.discounted_total_cents).to eq(8000)
      expect(payment.currency).to eq("cad")
      expect(payment.stripe_payment_id).to eq("sess_123")

      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(
        line_items: [ hash_including(price_data: hash_including(unit_amount: 4000), quantity: 2) ],
        success_url: include("payment_id=#{payment.id}"),
        metadata: hash_including(
          payment_id: payment.id,
          user_id: user.id,
          product_id: product.id,
          quantity: 2,
          discounted_unit_price_cents: 4000,
          discount_percent: 20
        )
      ))
    end

    it "returns 502 when Stripe raises" do
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::APIError.new("boom"))

      post "/purchases/start_stripe_payment", params: { user_id: user.id, product_id: product.id, quantity: 1 }

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)).to include("error" => "Payment failed to initiate with Stripe")
    end
  end
end 
