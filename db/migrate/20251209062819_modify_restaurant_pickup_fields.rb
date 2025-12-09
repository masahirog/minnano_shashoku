class ModifyRestaurantPickupFields < ActiveRecord::Migration[7.1]
  def change
    # pickup_address_detail を pickup_building_info にリネーム
    rename_column :restaurants, :pickup_address_detail, :pickup_building_info

    # 緯度と経度を追加
    add_column :restaurants, :pickup_latitude, :decimal, precision: 10, scale: 7
    add_column :restaurants, :pickup_longitude, :decimal, precision: 10, scale: 7
  end
end
