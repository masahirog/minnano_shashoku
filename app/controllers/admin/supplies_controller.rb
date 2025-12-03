module Admin
  class SuppliesController < Admin::ApplicationController
    # 拠点別在庫詳細ページ
    def by_location
      # すべての拠点を取得
      @own_locations = OwnLocation.all.order(:name)
      @companies = Company.all.order(:name)
      @restaurants = Restaurant.all.order(:name)

      # 各拠点の在庫数を集計
      @location_stock_counts = {}

      @own_locations.each do |location|
        count = SupplyStock.where(location_type: nil, location_name: location.name).count
        count += SupplyStock.where(location_type: 'OwnLocation', location_id: location.id).count
        @location_stock_counts["OwnLocation_#{location.id}"] = count
      end

      @companies.each do |location|
        count = SupplyStock.where(location_type: 'Company', location_id: location.id).count
        @location_stock_counts["Company_#{location.id}"] = count
      end

      @restaurants.each do |location|
        count = SupplyStock.where(location_type: 'Restaurant', location_id: location.id).count
        @location_stock_counts["Restaurant_#{location.id}"] = count
      end
    end

    # 特定の商品の拠点別在庫一覧
    def stocks_by_location
      @supply = Supply.find(params[:id])
      @stocks = SupplyStock.where(supply_id: @supply.id)
                           .includes(:supply)
                           .order(:location_type, :location_id)
    end
  end
end
