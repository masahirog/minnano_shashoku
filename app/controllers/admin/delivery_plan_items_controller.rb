module Admin
  class DeliveryPlanItemsController < Admin::ApplicationController
    before_action :set_delivery_plan
    before_action :set_delivery_plan_item, only: [:edit, :update, :destroy]

    def new
      @delivery_plan_item = @delivery_plan.delivery_plan_items.build
      # 次のsequence番号を自動設定
      @delivery_plan_item.sequence = (@delivery_plan.delivery_plan_items.maximum(:sequence) || 0) + 1
    end

    def create
      @delivery_plan_item = @delivery_plan.delivery_plan_items.build(delivery_plan_item_params)

      if @delivery_plan_item.save
        redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: 'アイテムを追加しました'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @delivery_plan_item.update(delivery_plan_item_params)
        redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: 'アイテムを更新しました'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @delivery_plan_item.destroy
      redirect_to admin_delivery_plans_path(date: @delivery_plan.delivery_date), notice: 'アイテムを削除しました'
    end

    private

    def set_delivery_plan
      @delivery_plan = DeliveryPlan.find(params[:delivery_plan_id])
    end

    def set_delivery_plan_item
      @delivery_plan_item = @delivery_plan.delivery_plan_items.find(params[:id])
    end

    def delivery_plan_item_params
      params.require(:delivery_plan_item).permit(
        :sequence, :action_type, :location_type, :location_id,
        :scheduled_time, :actual_time, :status, :meal_count, :notes
      )
    end
  end
end
