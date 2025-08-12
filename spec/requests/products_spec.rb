require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "GET /products" do
    let!(:product) { create(:product, redeem_price: 1500, inventory: 5) }

    it "returns a list of products with redeem_price_dollar" do
      get products_path

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      ids = body.map { |p| p["id"] }
      expect(ids).to include(product.id)
      item = body.find { |p| p["id"] == product.id }
      expect(item).to include(
        "id" => product.id,
        "name" => product.name,
        "inventory" => product.inventory
      )
      expect(item).to have_key("redeem_price_dollar")
      expect(item["redeem_price_dollar"]).to eq(product.redeem_price / 100.0)
    end
  end

  describe "GET /products/:id" do
    let(:product) { create(:product) }

    it "returns the product" do
      get product_path(product)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        "id" => product.id,
        "name" => product.name,
        "redeem_price" => product.redeem_price,
        "inventory" => product.inventory
      )
    end
  end

  describe "POST /products" do
    let(:attrs) { attributes_for(:product) }

    it "creates a product and returns 201" do
      params = { product: attrs }

      expect do
        post products_path, params: params.to_json, headers: json_headers
      end.to change(Product, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "name" => attrs[:name],
        "redeem_price" => attrs[:redeem_price],
        "inventory" => attrs[:inventory]
      )
    end
  end

  describe "PATCH /products/:id" do
    let(:product) { create(:product) }

    it "updates the product and returns 200" do
      patch product_path(product), params: { product: { name: "Updated Name" } }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Updated Name")
      expect(product.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /products/:id" do
    let!(:product) { create(:product) }

    it "destroys the product and returns 204" do
      expect do
        delete product_path(product)
      end.to change(Product, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end 