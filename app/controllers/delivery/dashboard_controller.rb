class Delivery::DashboardController < Delivery::BaseController
  def index
    @today_assignments = current_delivery_user.delivery_assignments
                                               .for_date(Date.current)
                                               .order(scheduled_time: :asc)
    @upcoming_assignments = current_delivery_user.delivery_assignments
                                                  .upcoming
                                                  .limit(10)
  end
end
