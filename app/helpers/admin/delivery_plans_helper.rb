module Admin::DeliveryPlansHelper
  def item_status_badge_class(item)
    case item.status
    when 'completed' then 'badge-success'
    when 'in_progress' then 'badge-warning'
    when 'pending' then 'badge-secondary'
    when 'skipped' then 'badge-danger'
    else 'badge-secondary'
    end
  end
end
