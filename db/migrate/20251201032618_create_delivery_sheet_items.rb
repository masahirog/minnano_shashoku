class CreateDeliverySheetItems < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_sheet_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :driver, foreign_key: true
      t.date :delivery_date, null: false

      # 配送詳細
      t.integer :sequence, null: false
      t.string :action_type, null: false
      t.string :delivery_type
      t.time :scheduled_time

      # 場所情報
      t.string :location_type
      t.string :location_name
      t.text :address
      t.string :phone
      t.boolean :has_setup, default: false

      # 詳細情報
      t.text :meal_info
      t.text :supplies_info
      t.text :notes
      t.string :photo_url

      t.timestamps
    end

    add_index :delivery_sheet_items, [:delivery_date, :sequence]
  end
end
