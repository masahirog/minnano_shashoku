class Delivery::ReportsController < Delivery::BaseController
  before_action :set_delivery_assignment, only: [:new, :create]

  # GET /delivery/assignments/:assignment_id/report/new
  def new
    @delivery_report = @delivery_assignment.build_delivery_report(
      delivery_user: current_delivery_user,
      started_at: @delivery_assignment.assigned_at,
      completed_at: Time.current
    )
  end

  # POST /delivery/assignments/:assignment_id/report
  def create
    @delivery_report = @delivery_assignment.build_delivery_report(delivery_report_params)
    @delivery_report.delivery_user = current_delivery_user
    @delivery_report.started_at ||= @delivery_assignment.assigned_at
    @delivery_report.completed_at ||= Time.current

    if @delivery_report.save
      # 配送割当のステータスを更新
      if @delivery_report.completed?
        @delivery_assignment.update(status: 'completed')
      elsif @delivery_report.failed? || @delivery_report.has_issue?
        @delivery_assignment.update(status: 'failed')
      end

      redirect_to delivery_assignment_path(@delivery_assignment), notice: '配送報告を送信しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /delivery/reports/:id
  def show
    @delivery_report = current_delivery_user.delivery_reports.find(params[:id])
    @delivery_assignment = @delivery_report.delivery_assignment
  rescue ActiveRecord::RecordNotFound
    redirect_to delivery_assignments_path, alert: '配送報告が見つかりません'
  end

  private

  def set_delivery_assignment
    @delivery_assignment = current_delivery_user.delivery_assignments.find(params[:assignment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to delivery_assignments_path, alert: '配送割当が見つかりません'
  end

  def delivery_report_params
    params.require(:delivery_report).permit(
      :report_type,
      :notes,
      :issue_type,
      :latitude,
      :longitude,
      :started_at,
      :completed_at,
      photos: []
    )
  end
end
