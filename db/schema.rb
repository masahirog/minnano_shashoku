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

ActiveRecord::Schema[7.1].define(version: 2025_12_01_033438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "formal_name", null: false
    t.string "contract_status", null: false
    t.bigint "staff_id"
    t.string "contact_person"
    t.string "contact_phone"
    t.string "contact_email"
    t.text "delivery_address"
    t.string "billing_email"
    t.string "billing_dept"
    t.string "billing_person_title"
    t.string "billing_person_name"
    t.integer "default_meal_count", default: 40
    t.boolean "paypay_enabled", default: false
    t.integer "paypay_employee_rate_1", default: 500
    t.integer "paypay_employee_rate_2"
    t.string "discount_type"
    t.integer "discount_amount", default: 0
    t.boolean "initial_fee_waived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_status"], name: "index_companies_on_contract_status"
    t.index ["name"], name: "index_companies_on_name"
    t.index ["staff_id"], name: "index_companies_on_staff_id"
  end

  create_table "delivery_companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_person"
    t.string "phone"
    t.string "email"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_sheet_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "driver_id"
    t.date "delivery_date", null: false
    t.integer "sequence", null: false
    t.string "action_type", null: false
    t.string "delivery_type"
    t.time "scheduled_time"
    t.string "location_type"
    t.string "location_name"
    t.text "address"
    t.string "phone"
    t.boolean "has_setup", default: false
    t.text "meal_info"
    t.text "supplies_info"
    t.text "notes"
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_date", "sequence"], name: "index_delivery_sheet_items_on_delivery_date_and_sequence"
    t.index ["driver_id"], name: "index_delivery_sheet_items_on_driver_id"
    t.index ["order_id"], name: "index_delivery_sheet_items_on_order_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.bigint "delivery_company_id", null: false
    t.string "name", null: false
    t.string "phone"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_company_id"], name: "index_drivers_on_delivery_company_id"
  end

  create_table "menus", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "price_per_meal", default: 649, null: false
    t.boolean "is_active", default: true
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "restaurant_id", null: false
    t.bigint "menu_id", null: false
    t.bigint "second_menu_id"
    t.bigint "delivery_company_id"
    t.string "order_type", null: false
    t.date "scheduled_date", null: false
    t.integer "delivery_group", default: 1
    t.integer "delivery_priority", default: 1
    t.integer "default_meal_count", null: false
    t.integer "confirmed_meal_count"
    t.string "status", default: "予定", null: false
    t.string "restaurant_status"
    t.string "delivery_company_status"
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["delivery_company_id"], name: "index_orders_on_delivery_company_id"
    t.index ["menu_id"], name: "index_orders_on_menu_id"
    t.index ["restaurant_id"], name: "index_orders_on_restaurant_id"
    t.index ["scheduled_date", "delivery_company_id"], name: "index_orders_on_scheduled_date_and_delivery_company_id"
    t.index ["scheduled_date"], name: "index_orders_on_scheduled_date"
    t.index ["second_menu_id"], name: "index_orders_on_second_menu_id"
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "staff_id"
    t.string "supplier_code"
    t.string "invoice_number"
    t.string "contract_status", null: false
    t.string "genre"
    t.string "phone"
    t.string "contact_person"
    t.string "contact_phone"
    t.string "contact_email"
    t.integer "max_capacity", null: false
    t.string "pickup_time_with_main"
    t.string "pickup_time_trial_only"
    t.text "pickup_address"
    t.string "closed_days", default: [], array: true
    t.boolean "has_delivery_fee", default: false
    t.integer "delivery_fee_per_meal", default: 0
    t.boolean "self_delivery", default: false
    t.boolean "trial_available", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_status"], name: "index_restaurants_on_contract_status"
    t.index ["name"], name: "index_restaurants_on_name"
    t.index ["staff_id"], name: "index_restaurants_on_staff_id"
  end

  create_table "staff", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "companies", "staff"
  add_foreign_key "delivery_sheet_items", "drivers"
  add_foreign_key "delivery_sheet_items", "orders"
  add_foreign_key "drivers", "delivery_companies"
  add_foreign_key "menus", "restaurants"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "delivery_companies"
  add_foreign_key "orders", "menus"
  add_foreign_key "orders", "menus", column: "second_menu_id"
  add_foreign_key "orders", "restaurants"
  add_foreign_key "restaurants", "staff"
end
