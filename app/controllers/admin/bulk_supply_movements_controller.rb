module Admin
  class BulkSupplyMovementsController < ApplicationController
    before_action :authenticate_admin

    def new
      @supplies = Supply.where(is_active: true).order(:name)
      @movement_types = SupplyMovement::MOVEMENT_TYPES
      @companies = Company.order(:name)
      @restaurants = Restaurant.order(:name)
      @delivery_companies = DeliveryCompany.order(:name)
      @own_locations = OwnLocation.where(is_active: true).order(:name)
    end

    def get_stocks
      location_type = params[:location_type]
      location_id = params[:location_id]

      stocks = {}

      if location_type.present? && location_id.present?
        # 特定の拠点の在庫
        SupplyStock.where(location_type: location_type, location_id: location_id).each do |stock|
          stocks[stock.supply_id] = stock.quantity
        end
      else
        # location_typeが空の場合は在庫なし（全て選択可能）
        stocks = {}
      end

      render json: stocks
    end

    def create
      supply_ids = params[:supply_ids] || []
      quantities = params[:quantities] || {}
      movement_type = params[:movement_type]

      if supply_ids.empty?
        flash[:error] = '備品を選択してください'
        redirect_to new_admin_bulk_supply_movement_path
        return
      end

      # 移動種別による拠点チェック
      if movement_type == '移動'
        if params[:from_location_type].blank? && params[:from_location_id].blank?
          # 本社倉庫からの移動はOK
        elsif params[:to_location_type].blank? && params[:to_location_id].blank?
          # 本社倉庫への移動はOK
        end
      elsif movement_type == '入荷'
        # 入荷の場合、移動元は不要
        params[:from_location_type] = nil
        params[:from_location_id] = nil
      elsif movement_type == '消費'
        # 消費の場合、移動先は不要
        params[:to_location_type] = nil
        params[:to_location_id] = nil
      end

      movement_count = 0
      errors = []

      supply_ids.each do |supply_id|
        quantity = quantities[supply_id].to_i

        # 数量が0または未入力の場合はスキップ
        if quantity <= 0
          supply = Supply.find(supply_id)
          errors << "#{supply.name}: 数量を入力してください"
          next
        end

        # 移動・消費の場合、在庫チェック
        if ['移動', '消費'].include?(movement_type)
          from_location_type = params[:from_location_type].presence
          from_location_id = params[:from_location_id].presence

          stock = if from_location_type && from_location_id
                    SupplyStock.find_by(
                      supply_id: supply_id,
                      location_type: from_location_type,
                      location_id: from_location_id
                    )
                  else
                    # 本社倉庫
                    SupplyStock.find_by(
                      supply_id: supply_id,
                      location_type: nil,
                      location_id: nil
                    )
                  end

          if stock.nil? || stock.quantity < quantity
            supply = Supply.find(supply_id)
            available = stock&.quantity || 0
            errors << "#{supply.name}: 在庫不足（在庫: #{available}、指定数量: #{quantity}）"
            next
          end
        end

        movement = SupplyMovement.new(
          supply_id: supply_id,
          movement_type: movement_type,
          quantity: quantity,
          from_location_type: params[:from_location_type],
          from_location_id: params[:from_location_id],
          to_location_type: params[:to_location_type],
          to_location_id: params[:to_location_id],
          movement_date: params[:movement_date],
          notes: params[:notes]
        )

        if movement.save
          movement_count += 1
        else
          supply = Supply.find(supply_id)
          errors << "#{supply.name}: #{movement.errors.full_messages.join(', ')}"
        end
      end

      if errors.empty? && movement_count > 0
        flash[:notice] = "#{movement_count}件の備品移動を登録しました"
        redirect_to admin_supply_movements_path
      else
        error_message = []
        error_message << "#{errors.join('; ')}" unless errors.empty?
        error_message << "登録する備品がありません" if movement_count == 0 && errors.empty?
        flash[:error] = "エラーが発生しました: #{error_message.join('; ')}"
        redirect_to new_admin_bulk_supply_movement_path
      end
    end

    private

    def authenticate_admin
      authenticate_admin_user!
    end
  end
end
