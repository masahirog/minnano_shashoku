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

ActiveRecord::Schema[7.1].define(version: 2025_12_07_072551) do
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

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "role"
    t.boolean "is_login_enabled", default: true, null: false
    t.string "phone"
    t.string "employee_number"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "formal_name", null: false
    t.string "contract_status", null: false
    t.bigint "admin_user_id"
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
    t.string "delivery_day_of_week"
    t.boolean "has_setup"
    t.string "digital_signage_id"
    t.date "first_delivery_date"
    t.date "discount_campaign_end_date"
    t.boolean "trial_billable"
    t.integer "trial_free_meal_count"
    t.date "trial_date"
    t.boolean "employee_burden_enabled"
    t.integer "employee_burden_amount"
    t.string "delivery_time_goal"
    t.string "pickup_time_goal"
    t.text "delivery_notes"
    t.text "pickup_notes"
    t.string "monthly_fee_type"
    t.integer "initial_fee_amount"
    t.date "delivery_fee_campaign_end_date"
    t.integer "delivery_fee_discount"
    t.integer "remote_delivery_fee"
    t.integer "special_delivery_fee"
    t.time "delivery_time_preferred"
    t.time "delivery_time_earliest"
    t.time "delivery_time_latest"
    t.integer "meal_count_min"
    t.integer "meal_count_max"
    t.string "color", default: "#2196f3"
    t.date "contract_end_date"
    t.index ["admin_user_id"], name: "index_companies_on_admin_user_id"
    t.index ["contract_status"], name: "index_companies_on_contract_status"
    t.index ["name"], name: "index_companies_on_name"
  end

  create_table "delivery_assignments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "delivery_user_id", null: false
    t.bigint "delivery_company_id", null: false
    t.date "scheduled_date", null: false
    t.time "scheduled_time"
    t.integer "sequence_number"
    t.string "status", default: "pending", null: false
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_company_id"], name: "index_delivery_assignments_on_delivery_company_id"
    t.index ["delivery_user_id", "scheduled_date", "status"], name: "index_delivery_assignments_on_user_date_status"
    t.index ["delivery_user_id"], name: "index_delivery_assignments_on_delivery_user_id"
    t.index ["order_id"], name: "index_delivery_assignments_on_order_id", unique: true
    t.index ["scheduled_date"], name: "index_delivery_assignments_on_scheduled_date"
    t.index ["status"], name: "index_delivery_assignments_on_status"
  end

  create_table "delivery_companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_person"
    t.string "phone"
    t.string "email"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "api_enabled", default: false, null: false
    t.string "api_key"
    t.json "service_area"
    t.index ["api_key"], name: "index_delivery_companies_on_api_key", unique: true
  end

  create_table "delivery_plan_item_orders", force: :cascade do |t|
    t.bigint "delivery_plan_item_id", null: false
    t.bigint "order_id", null: false
    t.string "action_role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_plan_item_id", "order_id"], name: "index_delivery_plan_item_orders_on_item_and_order", unique: true
    t.index ["delivery_plan_item_id"], name: "index_delivery_plan_item_orders_on_delivery_plan_item_id"
    t.index ["order_id"], name: "index_delivery_plan_item_orders_on_order_id"
  end

  create_table "delivery_plan_items", force: :cascade do |t|
    t.bigint "delivery_plan_id", null: false
    t.integer "sequence", null: false
    t.string "action_type", null: false
    t.string "location_type"
    t.bigint "location_id"
    t.time "scheduled_time"
    t.time "actual_time"
    t.string "status", default: "pending", null: false
    t.integer "meal_count"
    t.jsonb "supplies_info", default: {}
    t.text "notes"
    t.string "photo_url"
    t.string "completed_by"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_plan_id", "sequence"], name: "index_delivery_plan_items_on_delivery_plan_id_and_sequence"
    t.index ["delivery_plan_id"], name: "index_delivery_plan_items_on_delivery_plan_id"
    t.index ["location_type", "location_id"], name: "index_delivery_plan_items_on_location_type_and_location_id"
    t.index ["status"], name: "index_delivery_plan_items_on_status"
  end

  create_table "delivery_plans", force: :cascade do |t|
    t.bigint "delivery_company_id", null: false
    t.bigint "driver_id"
    t.date "delivery_date", null: false
    t.string "status", default: "draft", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_company_id"], name: "index_delivery_plans_on_delivery_company_id"
    t.index ["delivery_date", "delivery_company_id"], name: "index_delivery_plans_on_delivery_date_and_delivery_company_id"
    t.index ["delivery_date"], name: "index_delivery_plans_on_delivery_date"
    t.index ["driver_id"], name: "index_delivery_plans_on_driver_id"
    t.index ["status"], name: "index_delivery_plans_on_status"
  end

  create_table "delivery_reports", force: :cascade do |t|
    t.bigint "delivery_assignment_id", null: false
    t.bigint "delivery_user_id", null: false
    t.string "report_type", default: "completed", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.text "notes"
    t.string "issue_type"
    t.json "photos"
    t.text "signature_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_delivery_reports_on_completed_at"
    t.index ["delivery_assignment_id"], name: "index_delivery_reports_on_delivery_assignment_id", unique: true
    t.index ["delivery_user_id"], name: "index_delivery_reports_on_delivery_user_id"
    t.index ["report_type"], name: "index_delivery_reports_on_report_type"
  end

  create_table "delivery_routes", force: :cascade do |t|
    t.bigint "delivery_assignment_id", null: false
    t.bigint "delivery_user_id", null: false
    t.datetime "recorded_at", null: false
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.decimal "accuracy", precision: 5, scale: 2
    t.decimal "speed", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_assignment_id"], name: "index_delivery_routes_on_delivery_assignment_id"
    t.index ["delivery_user_id"], name: "index_delivery_routes_on_delivery_user_id"
    t.index ["recorded_at"], name: "index_delivery_routes_on_recorded_at"
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

  create_table "delivery_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "role", default: "driver", null: false
    t.bigint "delivery_company_id", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_sign_in_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_company_id"], name: "index_delivery_users_on_delivery_company_id"
    t.index ["email"], name: "index_delivery_users_on_email", unique: true
    t.index ["is_active"], name: "index_delivery_users_on_is_active"
    t.index ["reset_password_token"], name: "index_delivery_users_on_reset_password_token", unique: true
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

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "order_id"
    t.string "description", null: false
    t.integer "quantity", default: 1
    t.integer "unit_price", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["order_id"], name: "index_invoice_items_on_order_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "invoice_number", null: false
    t.date "issue_date", null: false
    t.date "payment_due_date", null: false
    t.date "billing_period_start", null: false
    t.date "billing_period_end", null: false
    t.integer "subtotal", default: 0
    t.integer "tax_amount", default: 0
    t.integer "total_amount", null: false
    t.string "status", default: "draft", null: false
    t.string "payment_status", default: "unpaid"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_period_start", "payment_status"], name: "index_invoices_on_billing_period_and_status"
    t.index ["billing_period_start"], name: "index_invoices_on_billing_period_start"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["issue_date"], name: "index_invoices_on_issue_date"
    t.index ["payment_due_date"], name: "index_invoices_on_payment_due_date"
    t.index ["payment_status"], name: "index_invoices_on_payment_status"
    t.index ["status"], name: "index_invoices_on_status"
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
    t.integer "tax_rate", default: 8
    t.index ["restaurant_id"], name: "index_menus_on_restaurant_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "menu_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price", null: false
    t.integer "subtotal", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.integer "tax_rate", default: 8
    t.index ["menu_id"], name: "index_order_items_on_menu_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "restaurant_id"
    t.bigint "delivery_company_id"
    t.string "order_type", null: false
    t.date "scheduled_date", null: false
    t.string "status", default: "予定", null: false
    t.string "restaurant_status"
    t.string "delivery_company_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recurring_order_id"
    t.boolean "menu_confirmed", default: false
    t.boolean "meal_count_confirmed", default: false
    t.datetime "confirmation_deadline"
    t.boolean "is_trial", default: false
    t.time "collection_time"
    t.time "warehouse_pickup_time"
    t.string "return_location"
    t.text "equipment_notes"
    t.text "delivery_notes"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.text "delivery_address"
    t.integer "total_meal_count"
    t.integer "subtotal"
    t.integer "tax"
    t.integer "delivery_fee", default: 0
    t.integer "total_price"
    t.text "memo"
    t.integer "discount_amount", default: 0
    t.integer "tax_8_percent", default: 0
    t.integer "tax_10_percent", default: 0
    t.integer "delivery_fee_tax", default: 0
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["delivery_company_id"], name: "index_orders_on_delivery_company_id"
    t.index ["is_trial"], name: "index_orders_on_is_trial"
    t.index ["recurring_order_id"], name: "index_orders_on_recurring_order_id"
    t.index ["restaurant_id"], name: "index_orders_on_restaurant_id"
    t.index ["scheduled_date", "delivery_company_id"], name: "index_orders_on_scheduled_date_and_delivery_company_id"
    t.index ["scheduled_date"], name: "index_orders_on_scheduled_date"
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "own_locations", force: :cascade do |t|
    t.string "name"
    t.string "location_type"
    t.string "address"
    t.string "phone"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.date "payment_date", null: false
    t.integer "amount", null: false
    t.string "payment_method"
    t.string "reference_number"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_method"], name: "index_payments_on_payment_method"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "subscribable_type", null: false
    t.bigint "subscribable_id", null: false
    t.text "endpoint", null: false
    t.string "p256dh_key", null: false
    t.string "auth_key", null: false
    t.text "user_agent"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["is_active"], name: "index_push_subscriptions_on_is_active"
    t.index ["subscribable_type", "subscribable_id"], name: "index_push_subscriptions_on_subscribable"
  end

  create_table "recurring_orders", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.integer "day_of_week", null: false
    t.integer "meal_count", default: 50, null: false
    t.time "delivery_time", null: false
    t.time "pickup_time"
    t.boolean "is_active", default: true, null: false
    t.string "status", default: "active", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "day_of_week"], name: "index_recurring_orders_on_company_id_and_day_of_week"
    t.index ["company_id"], name: "index_recurring_orders_on_company_id"
    t.index ["is_active"], name: "index_recurring_orders_on_is_active"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "admin_user_id"
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
    t.integer "capacity_per_day", default: 100
    t.integer "max_lots_per_day", default: 2
    t.time "pickup_time_earliest"
    t.time "pickup_time_latest"
    t.string "regular_holiday"
    t.index ["admin_user_id"], name: "index_restaurants_on_admin_user_id"
    t.index ["contract_status"], name: "index_restaurants_on_contract_status"
    t.index ["name"], name: "index_restaurants_on_name"
  end

  create_table "supplies", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.string "category", null: false
    t.string "unit", null: false
    t.integer "reorder_point"
    t.text "storage_guideline"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_supplies_on_category"
    t.index ["sku"], name: "index_supplies_on_sku", unique: true
  end

  create_table "supply_inventories", force: :cascade do |t|
    t.bigint "supply_id", null: false
    t.string "location_type"
    t.bigint "location_id"
    t.date "inventory_date", null: false
    t.decimal "theoretical_quantity", precision: 10, scale: 2
    t.decimal "actual_quantity", precision: 10, scale: 2
    t.decimal "difference", precision: 10, scale: 2
    t.text "notes"
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_supply_inventories_on_admin_user_id"
    t.index ["supply_id"], name: "index_supply_inventories_on_supply_id"
  end

  create_table "supply_movements", force: :cascade do |t|
    t.bigint "supply_id", null: false
    t.string "movement_type", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "from_location_type"
    t.bigint "from_location_id"
    t.string "to_location_type"
    t.bigint "to_location_id"
    t.date "movement_date", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "from_location_name"
    t.string "to_location_name"
    t.string "status", default: "確定", null: false
    t.index ["from_location_type", "from_location_id"], name: "index_supply_movements_on_from_location"
    t.index ["movement_date"], name: "index_supply_movements_on_movement_date"
    t.index ["movement_type"], name: "index_supply_movements_on_movement_type"
    t.index ["supply_id"], name: "index_supply_movements_on_supply_id"
    t.index ["to_location_type", "to_location_id"], name: "index_supply_movements_on_to_location"
  end

  create_table "supply_stocks", force: :cascade do |t|
    t.bigint "supply_id", null: false
    t.string "location_type"
    t.bigint "location_id"
    t.string "location_name"
    t.string "location_type_detail"
    t.decimal "quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "physical_count", precision: 10, scale: 2
    t.datetime "last_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_type", "location_id"], name: "index_supply_stocks_on_location"
    t.index ["supply_id", "location_type", "location_id", "location_name"], name: "index_supply_stocks_on_supply_and_location", unique: true
    t.index ["supply_id"], name: "index_supply_stocks_on_supply_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "companies", "admin_users"
  add_foreign_key "delivery_assignments", "delivery_companies"
  add_foreign_key "delivery_assignments", "delivery_users"
  add_foreign_key "delivery_assignments", "orders"
  add_foreign_key "delivery_plan_item_orders", "delivery_plan_items"
  add_foreign_key "delivery_plan_item_orders", "orders"
  add_foreign_key "delivery_plan_items", "delivery_plans"
  add_foreign_key "delivery_plans", "delivery_companies"
  add_foreign_key "delivery_plans", "delivery_users", column: "driver_id"
  add_foreign_key "delivery_reports", "delivery_assignments"
  add_foreign_key "delivery_reports", "delivery_users"
  add_foreign_key "delivery_routes", "delivery_assignments"
  add_foreign_key "delivery_routes", "delivery_users"
  add_foreign_key "delivery_sheet_items", "drivers"
  add_foreign_key "delivery_sheet_items", "orders"
  add_foreign_key "delivery_users", "delivery_companies"
  add_foreign_key "drivers", "delivery_companies"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "orders"
  add_foreign_key "invoices", "companies"
  add_foreign_key "menus", "restaurants"
  add_foreign_key "order_items", "menus"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "delivery_companies"
  add_foreign_key "orders", "recurring_orders"
  add_foreign_key "orders", "restaurants"
  add_foreign_key "payments", "invoices"
  add_foreign_key "recurring_orders", "companies"
  add_foreign_key "restaurants", "admin_users"
  add_foreign_key "supply_inventories", "admin_users"
  add_foreign_key "supply_inventories", "supplies"
  add_foreign_key "supply_movements", "supplies"
  add_foreign_key "supply_stocks", "supplies"
end
