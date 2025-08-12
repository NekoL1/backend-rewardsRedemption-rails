require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "GET /users" do
    it "returns a list of users" do
      user = User.create!(name: "Alice", phone: "123", email: "alice@example.com", point_balance: 500, vip_grade: 1)

      get users_path

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.map { |u| u["id"] }).to include(user.id)
    end
  end

  describe "GET /users/:id" do
    it "returns the user with expected fields and methods" do
      user = User.create!(name: "Bob", phone: "456", email: "bob@example.com", point_balance: 250, vip_grade: 2)

      get user_path(user)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        "id" => user.id,
        "name" => "Bob",
        "phone" => "456",
        "email" => "bob@example.com",
        "vip_grade" => 2
      )
      expect(body).to have_key("created_at")
      expect(body).to have_key("updated_at")
      expect(body["point_balance_dollar"]).to eq(2.5)
    end
  end

  describe "POST /users" do
    it "creates a user and returns 201" do
      params = { user: { name: "Carol", phone: "789", email: "carol@example.com", point_balance: 1234 } }

      expect do
        post users_path, params: params.to_json, headers: json_headers
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "name" => "Carol",
        "phone" => "789",
        "email" => "carol@example.com",
        "point_balance" => 1234
      )
    end
  end

  describe "PATCH /users/:id" do
    it "updates the user and returns 200" do
      user = User.create!(name: "Dave", phone: "111", email: "dave@example.com", point_balance: 0)

      patch user_path(user), params: { user: { name: "David" } }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("David")
      expect(user.reload.name).to eq("David")
    end
  end

  describe "DELETE /users/:id" do
    it "destroys the user and returns 204" do
      user = User.create!(name: "Eve", phone: "222", email: "eve@example.com", point_balance: 0)

      expect do
        delete user_path(user)
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /users/:id/point_balance" do
    it "returns the point balance in dollars" do
      user = User.create!(name: "Frank", phone: "333", email: "frank@example.com", point_balance: 987)

      get "/users/#{user.id}/point_balance"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("id" => user.id)
      expect(body["point_balance_dollar"]).to eq(9.87)
    end

    it "returns 404 when user not found" do
      get "/users/999999/point_balance"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("User not Found")
    end
  end

  describe "GET /users/:id/vip_grade" do
    it "returns the vip grade" do
      user = User.create!(name: "Grace", phone: "444", email: "grace@example.com", point_balance: 0, vip_grade: 3)

      get "/users/#{user.id}/vip_grade"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to eq({ "user_id" => user.id, "vip_grade" => 3 })
    end

    it "returns 404 when user not found" do
      get "/users/999999/vip_grade"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("User not Found")
    end
  end
end 