module Admin
  class SuppliesController < Admin::ApplicationController
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
  end
end
