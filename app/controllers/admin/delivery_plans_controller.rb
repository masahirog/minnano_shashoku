module Admin
  class DeliveryPlansController < Admin::ApplicationController
    before_action :set_delivery_plan, only: [:show, :edit, :update, :destroy, :add_orders, :reorder_items]

    def index
      @date = params[:date]&.to_date || Date.today

      # 未アサインのOrder（確定済みでDeliveryPlanに未割り当て）
      @unassigned_orders = Order.where(scheduled_date: @date, status: '確定')
                                .left_joins(:delivery_plan_item_orders)
                                .where(delivery_plan_item_orders: { id: nil })
                                .includes(:company, :restaurant)

      # 該当日のDeliveryPlans
      @delivery_plans = DeliveryPlan.includes(:delivery_company, :driver, delivery_plan_items: [:location, :orders])
                                    .where(delivery_date: @date)
                                    .order(:id)
    end

    def show
      @delivery_plan_items = @delivery_plan.delivery_plan_items.includes(:location, :orders).ordered
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
          format.turbo_stream { render turbo_stream: turbo_stream.prepend('delivery-plans', partial: 'delivery_plan_column', locals: { delivery_plan: @delivery_plan }) }
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

    # DeliveryPlanItemsの順序を変更
    def reorder_items
      params[:items].each_with_index do |item_id, index|
        DeliveryPlanItem.where(id: item_id).update_all(sequence: index + 1)
      end

      head :ok
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
