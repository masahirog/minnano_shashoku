module Admin
  class DeliveryAssignmentsController < Admin::ApplicationController
    before_action :set_delivery_assignment, only: [:show, :edit, :update, :destroy]

    # GET /admin/delivery_assignments
    def index
      @delivery_assignments = DeliveryAssignment
        .includes(:order, :delivery_user, :delivery_company)
        .order(scheduled_date: :desc, sequence_number: :asc)
        .page(params[:page])

      # フィルター適用
      if params[:scheduled_date].present?
        @delivery_assignments = @delivery_assignments.where(scheduled_date: params[:scheduled_date])
      end

      if params[:delivery_company_id].present?
        @delivery_assignments = @delivery_assignments.where(delivery_company_id: params[:delivery_company_id])
      end

      if params[:delivery_user_id].present?
        @delivery_assignments = @delivery_assignments.where(delivery_user_id: params[:delivery_user_id])
      end

      if params[:status].present?
        @delivery_assignments = @delivery_assignments.where(status: params[:status])
      end
    end

    # GET /admin/delivery_assignments/:id
    def show
    end

    # GET /admin/delivery_assignments/new
    def new
      @delivery_assignment = DeliveryAssignment.new
      @orders = Order.where(delivery_company_id: params[:delivery_company_id])
                     .left_joins(:delivery_assignment)
                     .where(delivery_assignments: { id: nil })
                     .order(scheduled_date: :desc)
      @delivery_users = DeliveryUser.active.order(:name)
    end

    # POST /admin/delivery_assignments
    def create
      service = AssignDeliveryService.new

      begin
        @delivery_assignment = service.assign(
          params[:delivery_assignment][:order_id],
          params[:delivery_assignment][:delivery_user_id],
          {
            scheduled_time: params[:delivery_assignment][:scheduled_time],
            sequence_number: params[:delivery_assignment][:sequence_number]
          }
        )

        redirect_to admin_delivery_assignment_path(@delivery_assignment), notice: '配送割当を作成しました'
      rescue AssignDeliveryService::AssignmentError => e
        flash.now[:alert] = e.message
        @orders = Order.left_joins(:delivery_assignment)
                       .where(delivery_assignments: { id: nil })
                       .order(scheduled_date: :desc)
        @delivery_users = DeliveryUser.active.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/delivery_assignments/:id/edit
    def edit
      @delivery_users = DeliveryUser.where(delivery_company_id: @delivery_assignment.delivery_company_id)
                                     .active
                                     .order(:name)
    end

    # PATCH /admin/delivery_assignments/:id
    def update
      if @delivery_assignment.update(delivery_assignment_params)
        redirect_to admin_delivery_assignment_path(@delivery_assignment), notice: '配送割当を更新しました'
      else
        @delivery_users = DeliveryUser.where(delivery_company_id: @delivery_assignment.delivery_company_id)
                                       .active
                                       .order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/delivery_assignments/:id
    def destroy
      service = AssignDeliveryService.new

      begin
        service.cancel(@delivery_assignment.id)
        redirect_to admin_delivery_assignments_path, notice: '配送割当を削除しました'
      rescue AssignDeliveryService::AssignmentError => e
        redirect_to admin_delivery_assignment_path(@delivery_assignment), alert: e.message
      end
    end

    # POST /admin/delivery_assignments/bulk_assign
    def bulk_assign
      service = AssignDeliveryService.new

      result = service.bulk_assign(
        params[:order_ids],
        params[:delivery_user_id]
      )

      if result[:errors].empty?
        redirect_to admin_delivery_assignments_path, notice: "#{result[:assigned]}件の配送を割り当てました"
      else
        redirect_to admin_delivery_assignments_path,
                    alert: "#{result[:assigned]}件成功、#{result[:failed]}件失敗しました"
      end
    end

    private

    def set_delivery_assignment
      @delivery_assignment = DeliveryAssignment.find(params[:id])
    end

    def delivery_assignment_params
      params.require(:delivery_assignment).permit(
        :delivery_user_id,
        :scheduled_time,
        :sequence_number,
        :status
      )
    end
  end
end
