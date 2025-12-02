module Admin
  class SupplyStocksController < Admin::ApplicationController
    # 在庫の直接編集を禁止し、備品移動登録を通じてのみ変更可能にする
    before_action :redirect_to_movements, only: [:new, :create, :edit, :update, :destroy]

    # 拠点別在庫詳細ページ
    def by_location
      supply_id = params[:supply_id]

      if supply_id.present?
        @supply = Supply.find(supply_id)
        @stocks = SupplyStock.where(supply_id: supply_id).includes(:supply).order(:location_type, :location_id)
      else
        @stocks = SupplyStock.includes(:supply).order('supplies.name', :location_type, :location_id)
      end
    end

    private

    def redirect_to_movements
      redirect_to new_admin_bulk_supply_movement_path,
                  alert: "在庫の直接編集はできません。備品移動登録から在庫を調整してください。"
    end
  end
end
