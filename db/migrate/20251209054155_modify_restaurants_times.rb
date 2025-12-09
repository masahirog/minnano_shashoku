class ModifyRestaurantsTimes < ActiveRecord::Migration[7.1]
  def change
    # 不要カラムの削除
    remove_column :restaurants, :has_delivery_fee, :boolean
    remove_column :restaurants, :delivery_fee_per_meal, :integer
    remove_column :restaurants, :pickup_time_with_main, :string
    remove_column :restaurants, :pickup_time_trial_only, :string
    remove_column :restaurants, :self_delivery, :boolean
    remove_column :restaurants, :trial_available, :boolean
    remove_column :restaurants, :max_lots_per_day, :integer
    remove_column :restaurants, :pickup_time_earliest, :time
    remove_column :restaurants, :pickup_time_latest, :time

    # デフォルト時間カラムの追加
    add_column :restaurants, :default_pickup_time, :time
    add_column :restaurants, :default_return_time, :time
  end
end
