class AddDeliveryFlowFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    # 配送フロー関連（業務マニュアルに基づく追加）
    add_column :orders, :is_trial, :boolean, default: false  # 試食会か本導入か
    add_column :orders, :collection_time, :time  # 器材回収時刻（企業から）
    add_column :orders, :warehouse_pickup_time, :time  # 倉庫での器材集荷時刻
    add_column :orders, :return_location, :string  # 器材返却先（'warehouse'/'restaurant'）
    add_column :orders, :equipment_notes, :text  # 器材メモ（Phase 1簡易対応）

    add_index :orders, :is_trial
  end
end
