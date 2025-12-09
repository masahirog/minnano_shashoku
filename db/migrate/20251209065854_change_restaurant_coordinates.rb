class ChangeRestaurantCoordinates < ActiveRecord::Migration[7.1]
  def change
    # 既存の緯度経度カラムを削除
    remove_column :restaurants, :pickup_latitude, :decimal
    remove_column :restaurants, :pickup_longitude, :decimal

    # 統合した座標カラムを追加
    add_column :restaurants, :pickup_coordinates, :string
  end
end
