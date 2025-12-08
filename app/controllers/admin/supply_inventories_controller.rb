module Admin
  class SupplyInventoriesController < ApplicationController
    before_action :authenticate_admin

    def index
      @q = SupplyInventory.ransack(params[:q])
      @supply_inventories = @q.result
                              .includes(:supply, :location, :admin_user)
                              .order(inventory_date: :desc, created_at: :desc)
                              .page(params[:page])
                              .per(20)
    end

    def new
      @inventory_date = params[:inventory_date]&.to_date || Date.today
      @location_type = params[:location_type]
      @location_id = params[:location_id]

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
      end
    end

    def create
      @inventory_date = params[:inventory_date]
      @location_type = params[:location_type]
      @location_id = params[:location_id]

      errors = []
      success_count = 0

      if params[:inventories].present?
        params[:inventories].each do |supply_id, data|
          actual_quantity = data[:actual_quantity].to_f
          theoretical_quantity = data[:theoretical_quantity].to_f

          next if actual_quantity.zero? && theoretical_quantity.zero?

          inventory = SupplyInventory.new(
            supply_id: supply_id,
            location_type: @location_type,
            location_id: @location_id,
            inventory_date: @inventory_date,
            theoretical_quantity: theoretical_quantity,
            actual_quantity: actual_quantity,
            notes: data[:notes],
            admin_user_id: current_admin_user.id
          )

          if inventory.save
            success_count += 1
          else
            supply = Supply.find(supply_id)
            errors << "#{supply.name}: #{inventory.errors.full_messages.join(', ')}"
          end
        end
      end

      if errors.empty? && success_count > 0
        flash[:notice] = "#{success_count}件の棚卸しを登録しました"
        redirect_to admin_supply_inventories_path
      else
        error_message = []
        error_message << errors.join('; ') unless errors.empty?
        error_message << "棚卸しする備品がありません" if success_count == 0 && errors.empty?
        flash[:error] = "エラーが発生しました: #{error_message.join('; ')}"
        redirect_to new_admin_supply_inventory_path(
          inventory_date: @inventory_date,
          location_type: @location_type,
          location_id: @location_id
        )
      end
    end

    def show
      @supply_inventory = SupplyInventory.find(params[:id])
    end

    private

    def authenticate_admin
      authenticate_admin_user!
    end
  end
end
