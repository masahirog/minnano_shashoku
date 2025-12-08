class UpdateRecurringOrdersAndCompanies < ActiveRecord::Migration[7.1]
  def change
    # companiesテーブルにcontract_end_dateを追加
    add_column :companies, :contract_end_date, :date

    # recurring_ordersテーブルから不要なカラムを削除
    remove_column :recurring_orders, :restaurant_id, :bigint
    remove_column :recurring_orders, :menu_id, :bigint
    remove_column :recurring_orders, :frequency, :string
    remove_column :recurring_orders, :is_trial, :boolean
    remove_column :recurring_orders, :collection_time, :time
    remove_column :recurring_orders, :warehouse_pickup_time, :time
    remove_column :recurring_orders, :return_location, :string
    remove_column :recurring_orders, :equipment_notes, :text
    remove_column :recurring_orders, :start_date, :date
    remove_column :recurring_orders, :end_date, :date

    # default_meal_count → meal_count に変更
    rename_column :recurring_orders, :default_meal_count, :meal_count
  end
end
