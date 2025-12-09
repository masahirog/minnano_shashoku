module Admin
  class DeliveryPlansController < Admin::ApplicationController
    before_action :set_delivery_plan, only: [:show, :edit, :update, :destroy, :add_orders, :reorder_items, :move_items, :update_item_time]

    def index
      @date = params[:date]&.to_date || Date.today

      # 未アサインのOrder（DeliveryPlanItemsがすべて未アサインのOrder）
      # DeliveryPlanItemsが1つでもdelivery_plan_idを持つOrderは除外
      assigned_order_ids = DeliveryPlanItem.where.not(delivery_plan_id: nil)
                                           .joins(:order)
                                           .where(orders: { scheduled_date: @date })
                                           .distinct
                                           .pluck(:order_id)

      @unassigned_orders = Order.where(scheduled_date: @date)
                                .where.not(id: assigned_order_ids)
                                .includes(:company, :restaurant, :delivery_company)
                                .order(:id)

      # 該当日のDeliveryPlans
      @delivery_plans = DeliveryPlan.includes(:delivery_company, :driver, delivery_plan_items: [:restaurant, :company, :own_location, :order])
                                    .where(delivery_date: @date)
                                    .order(:id)
    end

    def show
      @delivery_plan_items = @delivery_plan.delivery_plan_items.includes(:restaurant, :company, :own_location, :order).ordered
    end

    def new
      @delivery_plan = DeliveryPlan.new(
        delivery_date: params[:date]&.to_date || Date.today,
        status: 'draft'
      )
    end

    def create
      @delivery_plan = DeliveryPlan.new(delivery_plan_params)

      if @delivery_plan.save
        respond_to do |format|
          format.html { redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: '配送計画を作成しました' }
          format.turbo_stream { render turbo_stream: turbo_stream.prepend('delivery-plans', partial: 'plan_column', locals: { plan: @delivery_plan }) }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @delivery_plan.update(delivery_plan_params)
        redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: '配送計画を更新しました'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      date = @delivery_plan.delivery_date
      @delivery_plan.destroy
      redirect_to admin_delivery_plans_path(date: date), notice: '配送計画を削除しました'
    end

    # Orderを追加して自動生成
    def add_orders
      order_ids = params[:order_ids] || [params[:order_id]]

      @delivery_plan.auto_generate_items_from_orders(order_ids)

      respond_to do |format|
        format.json { render json: { success: true, message: "#{order_ids.size}件のOrderを追加しました" } }
        format.html { redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: "#{order_ids.size}件のOrderを追加しました" }
      end
    rescue => e
      respond_to do |format|
        format.json { render json: { success: false, message: e.message }, status: :unprocessable_entity }
        format.html { redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), alert: "エラー: #{e.message}" }
      end
    end

    # DeliveryPlanItemsの順序を変更（現在は時間で管理するため実質不要だが、互換性のため残す）
    def reorder_items
      # scheduled_timeで順序が管理されているため、特に処理不要
      head :ok
    end

    # DeliveryPlanItemsを別のプランに一括移動（時間は保持）
    def move_items
      item_ids = params[:item_ids] || []
      from_plan_id = params[:from_plan_id]
      to_plan_id = @delivery_plan.id

      if item_ids.empty?
        render json: { success: false, message: '移動するアイテムが指定されていません' }, status: :unprocessable_entity
        return
      end

      # 指定されたアイテムを新しいプランに移動（時間は変更しない）
      DeliveryPlanItem.where(id: item_ids, delivery_plan_id: from_plan_id)
                      .update_all(delivery_plan_id: to_plan_id)

      render json: { success: true, message: "#{item_ids.size}件のアイテムを移動しました" }
    rescue => e
      render json: { success: false, message: e.message }, status: :unprocessable_entity
    end

    # DeliveryPlanItemの時間を更新
    def update_item_time
      item_id = params[:item_id]
      scheduled_time = params[:scheduled_time]

      if item_id.blank? || scheduled_time.blank?
        render json: { success: false, message: 'パラメータが不足しています' }, status: :unprocessable_entity
        return
      end

      item = @delivery_plan.delivery_plan_items.find(item_id)
      date = @delivery_plan.delivery_date
      time_obj = Time.zone.parse("#{date} #{scheduled_time}")

      item.update(scheduled_time: time_obj)

      render json: { success: true, message: '時間を更新しました' }
    rescue => e
      render json: { success: false, message: e.message }, status: :unprocessable_entity
    end

    # 配送計画を自動生成
    def auto_generate
      date = params[:date]&.to_date || Date.today
      delivery_company_id = params[:delivery_company_id]

      generator = DeliveryPlanGenerator.new(
        date: date,
        delivery_company_id: delivery_company_id
      )

      result = generator.generate

      if result[:success]
        redirect_to admin_delivery_plans_path(date: date),
                    notice: "#{result[:count]}件の配送計画を自動生成しました"
      else
        redirect_to admin_delivery_plans_path(date: date),
                    alert: "配送計画の生成に失敗しました: #{result[:errors].join(', ')}"
      end
    end

    private

    def set_delivery_plan
      @delivery_plan = DeliveryPlan.find(params[:id])
    end

    def delivery_plan_params
      params.require(:delivery_plan).permit(:delivery_company_id, :driver_id, :delivery_date, :status, :notes)
    end
  end
end
