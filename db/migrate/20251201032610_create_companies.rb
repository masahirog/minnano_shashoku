class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :formal_name, null: false
      t.string :contract_status, null: false
      t.references :staff, foreign_key: true

      # クライアント情報
      t.string :contact_person
      t.string :contact_phone
      t.string :contact_email
      t.text :delivery_address

      # 請求情報
      t.string :billing_email
      t.string :billing_dept
      t.string :billing_person_title
      t.string :billing_person_name

      # 設定
      t.integer :default_meal_count, default: 40

      # PayPay設定（将来用）
      t.boolean :paypay_enabled, default: false
      t.integer :paypay_employee_rate_1, default: 500
      t.integer :paypay_employee_rate_2

      # 割引設定（将来用）
      t.string :discount_type
      t.integer :discount_amount, default: 0
      t.boolean :initial_fee_waived, default: false

      t.timestamps
    end

    add_index :companies, :name
    add_index :companies, :contract_status
  end
end
