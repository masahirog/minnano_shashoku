class CreateRestaurants < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurants do |t|
      t.string :name, null: false
      t.references :staff, foreign_key: true
      t.string :supplier_code
      t.string :invoice_number
      t.string :contract_status, null: false
      t.string :genre

      # 連絡先
      t.string :phone
      t.string :contact_person
      t.string :contact_phone
      t.string :contact_email

      # 配送設定
      t.integer :max_capacity, null: false
      t.string :pickup_time_with_main
      t.string :pickup_time_trial_only
      t.text :pickup_address
      t.string :closed_days, array: true, default: []

      # 特殊設定
      t.boolean :has_delivery_fee, default: false
      t.integer :delivery_fee_per_meal, default: 0
      t.boolean :self_delivery, default: false
      t.boolean :trial_available, default: true

      t.timestamps
    end

    add_index :restaurants, :name
    add_index :restaurants, :contract_status
  end
end
