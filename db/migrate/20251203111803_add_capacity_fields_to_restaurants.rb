class AddCapacityFieldsToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :capacity_per_day, :integer, default: 100  # 1日の製造キャパ（食数）
    add_column :restaurants, :max_lots_per_day, :integer, default: 2  # 1日の最大ロット数
    add_column :restaurants, :pickup_time_earliest, :time  # 集荷可能最早時間
    add_column :restaurants, :pickup_time_latest, :time  # 集荷可能最遅時間
    add_column :restaurants, :regular_holiday, :string  # '0,6' = 日曜・土曜
  end
end
