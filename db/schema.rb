# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_13_040535) do
  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "currency", default: "cad", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "original_unit_price_cents"
    t.integer "discounted_unit_price_cents"
    t.integer "discount_percent"
    t.integer "original_total_cents"
    t.integer "discounted_total_cents"
    t.integer "product_id"
    t.integer "quantity"
    t.index ["product_id"], name: "index_payments_on_product_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.integer "redeem_price"
    t.integer "inventory"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.integer "payment_id", null: false
    t.integer "quantity"
    t.integer "original_unit_price_cents"
    t.integer "discount_percent"
    t.integer "unit_price_cents"
    t.integer "total_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_purchases_on_payment_id"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "redemptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.integer "redeem_price"
    t.integer "redeem_points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vip_grade", default: 0, null: false
    t.integer "discount", default: 0, null: false
    t.integer "payment_id"
    t.string "payment_method", default: "points", null: false
    t.index ["payment_id"], name: "index_redemptions_on_payment_id"
    t.index ["product_id"], name: "index_redemptions_on_product_id"
    t.index ["user_id"], name: "index_redemptions_on_user_id"
  end

  create_table "reward_transactions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "purchase_id"
    t.integer "points", null: false
    t.integer "amount_cents"
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_reward_transactions_on_kind"
    t.index ["purchase_id", "kind"], name: "index_reward_transactions_on_purchase_id_and_kind", unique: true, where: "kind = 'earn'"
    t.index ["purchase_id"], name: "index_reward_transactions_on_purchase_id"
    t.index ["user_id"], name: "index_reward_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.integer "point_balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vip_grade", default: 0, null: false
  end

  add_foreign_key "payments", "products"
  add_foreign_key "payments", "users"
  add_foreign_key "purchases", "payments"
  add_foreign_key "purchases", "products"
  add_foreign_key "purchases", "users"
  add_foreign_key "redemptions", "payments"
  add_foreign_key "redemptions", "products"
  add_foreign_key "redemptions", "users"
  add_foreign_key "reward_transactions", "purchases"
  add_foreign_key "reward_transactions", "users"
end
