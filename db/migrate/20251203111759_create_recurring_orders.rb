class CreateRecurringOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_orders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.references :menu, null: true, foreign_key: true
      t.references :delivery_company, null: true, foreign_key: true

      # スケジュール設定
      t.integer :day_of_week, null: false  # 0:日曜 〜 6:土曜
      t.string :frequency, null: false, default: 'weekly'  # 'weekly', 'biweekly', 'monthly'
      t.date :start_date, null: false
      t.date :end_date  # null = 無期限

      # 案件情報
      t.integer :default_meal_count, null: false, default: 50
      t.time :delivery_time, null: false
      t.time :pickup_time

      # 配送フロー関連（業務マニュアルに基づく追加）
      t.boolean :is_trial, null: false, default: false  # 試食会か本導入か
      t.time :collection_time  # 器材回収時刻（企業から）
      t.time :warehouse_pickup_time  # 倉庫での器材集荷時刻
      t.string :return_location, default: 'warehouse'  # 器材返却先（'warehouse'/'restaurant'）
      t.text :equipment_notes  # 器材メモ（Phase 1簡易対応）

      # ステータス
      t.boolean :is_active, null: false, default: true
      t.string :status, null: false, default: 'active'  # 'active', 'paused', 'completed'

      # メモ
      t.text :notes

      t.timestamps
    end

    add_index :recurring_orders, [:company_id, :day_of_week]
    add_index :recurring_orders, [:restaurant_id, :day_of_week]
    add_index :recurring_orders, :start_date
    add_index :recurring_orders, :is_active
  end
end
