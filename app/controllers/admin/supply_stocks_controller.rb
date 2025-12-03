module Admin
  class SupplyStocksController < Admin::ApplicationController
    # 在庫の直接編集を禁止し、備品移動登録を通じてのみ変更可能にする
    before_action :redirect_to_movements, only: [:new, :create, :edit, :update, :destroy]

    # 在庫詳細ページ
    def show
      @stock = SupplyStock.find(params[:id])
      @movements = @stock.related_movements
      super
    end

    # 拠点別在庫詳細ページ
    def by_location
      supply_id = params[:supply_id]
      location_type = params[:location_type]
      location_id = params[:location_id]

      # 拠点指定がある場合
      if location_type.present? && location_id.present?
        @location_type = location_type
        @location_id = location_id

        # 拠点情報を取得
        @location = case location_type
                    when 'OwnLocation'
                      OwnLocation.find(location_id)
                    when 'Company'
                      Company.find(location_id)
                    when 'Restaurant'
                      Restaurant.find(location_id)
                    end

        # 該当拠点の在庫を取得
        @stocks = SupplyStock.where(location_type: location_type, location_id: location_id)
                             .includes(:supply)
                             .order('supplies.name')

        # OwnLocationの場合はlocation_type=nilのデータも含める
        if location_type == 'OwnLocation'
          nil_stocks = SupplyStock.where(location_type: nil, location_name: @location.name)
                                  .includes(:supply)
                                  .order('supplies.name')
          @stocks = (@stocks.to_a + nil_stocks.to_a).uniq
        end
      elsif supply_id.present?
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
