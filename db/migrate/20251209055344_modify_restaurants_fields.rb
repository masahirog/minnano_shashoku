class ModifyRestaurantsFields < ActiveRecord::Migration[7.1]
  def change
    # max_capacity を削除（capacity_per_day と重複）
    remove_column :restaurants, :max_capacity, :integer

    # 集荷関連のカラムを追加
    add_column :restaurants, :pickup_notes, :text
    add_column :restaurants, :pickup_address_detail, :text
  end
end
