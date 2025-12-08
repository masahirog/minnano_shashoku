class Delivery::AssignmentsController < Delivery::BaseController
  before_action :set_delivery_assignment, only: [:show, :update_status]

  # GET /delivery/assignments
  def index
    @assignments = current_delivery_user.delivery_assignments
                                         .includes(:order => [:company, :restaurant, :menus])
                                         .order(scheduled_date: :asc, scheduled_time: :asc, sequence_number: :asc)

    # 日付フィルター
    if params[:date].present?
      filter_date = Date.parse(params[:date])
      @assignments = @assignments.for_date(filter_date)
    elsif params[:filter] == 'today'
      @assignments = @assignments.today
    elsif params[:filter] == 'week'
      @assignments = @assignments.where('scheduled_date >= ? AND scheduled_date <= ?', Date.current, Date.current + 6.days)
    else
      # デフォルトは今後の配送のみ
      @assignments = @assignments.where('scheduled_date >= ?', Date.current)
    end

    # ステータスフィルター
    if params[:status].present?
      case params[:status]
      when 'pending'
        @assignments = @assignments.pending
      when 'preparing'
        @assignments = @assignments.preparing
      when 'in_transit'
        @assignments = @assignments.in_transit
      when 'completed'
        @assignments = @assignments.completed
      when 'failed'
        @assignments = @assignments.failed
      when 'active'
        @assignments = @assignments.active
      end
    end
  end

  # GET /delivery/assignments/:id
  def show
    @order = @delivery_assignment.order
    @delivery_report = @delivery_assignment.delivery_report || @delivery_assignment.build_delivery_report
  end

  # PATCH /delivery/assignments/:id/update_status
  def update_status
    new_status = params[:status]

    case new_status
    when 'preparing'
      if @delivery_assignment.start_preparing!
        redirect_to delivery_assignment_path(@delivery_assignment), notice: '配送準備を開始しました'
      else
        redirect_to delivery_assignment_path(@delivery_assignment), alert: '配送準備を開始できませんでした'
      end
    when 'in_transit'
      if @delivery_assignment.start_transit!
        redirect_to delivery_assignment_path(@delivery_assignment), notice: '配送を開始しました'
      else
        redirect_to delivery_assignment_path(@delivery_assignment), alert: '配送を開始できませんでした'
      end
    when 'completed'
      if @delivery_assignment.complete!
        redirect_to delivery_assignment_path(@delivery_assignment), notice: '配送を完了しました'
      else
        redirect_to delivery_assignment_path(@delivery_assignment), alert: '配送を完了できませんでした'
      end
    when 'failed'
      if @delivery_assignment.mark_as_failed!
        redirect_to delivery_assignment_path(@delivery_assignment), notice: '配送を失敗としてマークしました'
      else
        redirect_to delivery_assignment_path(@delivery_assignment), alert: 'ステータスの更新に失敗しました'
      end
    else
      redirect_to delivery_assignment_path(@delivery_assignment), alert: '無効なステータスです'
    end
  end

  private

  def set_delivery_assignment
    @delivery_assignment = current_delivery_user.delivery_assignments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to delivery_assignments_path, alert: '配送割当が見つかりません'
  end
end
