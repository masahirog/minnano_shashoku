class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.references :menu, null: false, foreign_key: true
      t.references :second_menu, foreign_key: { to_table: :menus }
      t.references :delivery_company, foreign_key: true

      # 配送設定
      t.string :order_type, null: false
      t.date :scheduled_date, null: false
      t.integer :delivery_group, default: 1
      t.integer :delivery_priority, default: 1

      # 食数
      t.integer :default_meal_count, null: false
      t.integer :confirmed_meal_count

      # ステータス
      t.string :status, null: false, default: '予定'
      t.string :restaurant_status
      t.string :delivery_company_status

      # 将来の拡張用
      t.jsonb :options, default: {}

      t.timestamps
    end

    add_index :orders, :scheduled_date
    add_index :orders, :status
    add_index :orders, [:scheduled_date, :delivery_company_id]
  end
end
