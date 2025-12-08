module Admin
  class SupplyForecastsController < ApplicationController
    before_action :authenticate_admin

    def index
      @location_type = params[:location_type] || 'OwnLocation'
      @location_id = params[:location_id]
      @days_ahead = (params[:days_ahead] || 7).to_i

      # 拠点選択用データ
      @companies = Company.order(:name)
      @restaurants = Restaurant.order(:name)
      @delivery_companies = DeliveryCompany.order(:name)
      @own_locations = OwnLocation.where(is_active: true).order(:name)

      if @location_type.present? && @location_id.present?
        # 選択された拠点の在庫を取得
        @stocks = SupplyStock.where(
          location_type: @location_type,
          location_id: @location_id
        ).includes(:supply).order('supplies.name')

        @location = case @location_type
                    when 'Company'
                      Company.find(@location_id)
                    when 'Restaurant'
                      Restaurant.find(@location_id)
                    when 'DeliveryCompany'
                      DeliveryCompany.find(@location_id)
                    when 'OwnLocation'
                      OwnLocation.find(@location_id)
                    end

        # 各在庫の予測を計算
        @forecasts = @stocks.map do |stock|
          target_date = Date.today + @days_ahead.days
          predicted_qty = stock.predicted_quantity(target_date)
          reorder_date = stock.first_reorder_date(@days_ahead)

          {
            stock: stock,
            current_quantity: stock.quantity,
            predicted_quantity: predicted_qty,
            reorder_date: reorder_date,
            needs_attention: reorder_date.present?
          }
        end
      end
    end

    def show
      @stock = SupplyStock.find(params[:id])
      @days_ahead = (params[:days_ahead] || 7).to_i

      # 在庫推移を取得
      @transitions = @stock.quantity_transitions(
        Date.today,
        Date.today + @days_ahead.days
      )

      # グラフ用データ
      @chart_data = {
        labels: @transitions.map { |t| l(t[:date], format: :short) },
        quantities: @transitions.map { |t| t[:quantity] },
        reorder_point: @stock.supply.reorder_point
      }

      # 予定の移動一覧
      @planned_movements = SupplyMovement.where(supply_id: @stock.supply_id)
                                         .where("movement_date >= ? AND movement_date <= ?", Date.today, Date.today + @days_ahead.days)
                                         .where(
                                           "(from_location_type = ? AND from_location_id = ?) OR (to_location_type = ? AND to_location_id = ?)",
                                           @stock.location_type, @stock.location_id,
                                           @stock.location_type, @stock.location_id
                                         )
                                         .order(:movement_date, :created_at)
    end

    private

    def authenticate_admin
      authenticate_admin_user!
    end
  end
end
