require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "GET /users" do
    let!(:user) { create(:user) }

    it "returns a list of users" do
      get users_path

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.map { |u| u["id"] }).to include(user.id)
    end
  end

  describe "GET /users/:id" do
    let(:user) { create(:user, point_balance: 250, vip_grade: 2) }

    it "returns the user with expected fields and methods" do
      get user_path(user)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include(
        "id" => user.id,
        "name" => user.name,
        "phone" => user.phone,
        "email" => user.email,
        "vip_grade" => user.vip_grade
      )
      expect(body).to have_key("created_at")
      expect(body).to have_key("updated_at")
      expect(body["point_balance_dollar"]).to eq(user.point_balance / 100.0)
    end
  end

  describe "POST /users" do
    let(:attrs) { attributes_for(:user) }

    it "creates a user and returns 201" do
      params = { user: attrs }

      expect do
        post users_path, params: params.to_json, headers: json_headers
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "name" => attrs[:name],
        "phone" => attrs[:phone],
        "email" => attrs[:email],
        "point_balance" => attrs[:point_balance]
      )
    end
  end

  describe "PATCH /users/:id" do
    let(:user) { create(:user) }

    it "updates the user and returns 200" do
      patch user_path(user), params: { user: { name: "David" } }.to_json, headers: json_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("David")
      expect(user.reload.name).to eq("David")
    end
  end

  describe "DELETE /users/:id" do
    let!(:user) { create(:user) }

    it "destroys the user and returns 204" do
      expect do
        delete user_path(user)
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /users/:id/point_balance" do
    let(:user) { create(:user, point_balance: 987) }

    it "returns the point balance in dollars" do
      get "/users/#{user.id}/point_balance"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("id" => user.id)
      expect(body["point_balance_dollar"]).to eq(user.point_balance / 100.0)
    end

    it "returns 404 when user not found" do
      get "/users/999999/point_balance"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("User not Found")
    end
  end

  describe "GET /users/:id/vip_grade" do
    let(:user) { create(:user, vip_grade: 3) }

    it "returns the vip grade" do
      get "/users/#{user.id}/vip_grade"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to eq({ "user_id" => user.id, "vip_grade" => user.vip_grade })
    end

    it "returns 404 when user not found" do
      get "/users/999999/vip_grade"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("User not Found")
    end
  end
end
