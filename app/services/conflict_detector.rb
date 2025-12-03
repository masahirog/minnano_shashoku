# 案件のコンフリクト検出サービス
class ConflictDetector
  # 指定日のすべてのコンフリクトを検出
  def self.detect_for_date(date)
    orders = Order.includes(:restaurant, :company, :menu)
                  .where(scheduled_date: date)
                  .where.not(status: 'cancelled')

    conflicts = []

    # 各案件のコンフリクトをチェック
    orders.each do |order|
      order_conflicts = detect_for_order(order)
      if order_conflicts.any?
        conflicts << {
          order: order,
          conflicts: order_conflicts
        }
      end
    end

    conflicts
  end

  # 指定期間のすべてのコンフリクトを検出
  def self.detect_for_range(start_date, end_date)
    all_conflicts = {}

    (start_date..end_date).each do |date|
      date_conflicts = detect_for_date(date)
      all_conflicts[date] = date_conflicts if date_conflicts.any?
    end

    all_conflicts
  end

  # 単一の案件のコンフリクトを検出
  def self.detect_for_order(order)
    conflicts = []

    # 1. キャパシティオーバー検出
    capacity_conflict = check_restaurant_capacity(order)
    conflicts << capacity_conflict if capacity_conflict

    # 2. ドライバー重複検出（将来実装予定）
    # driver_conflict = check_driver_conflict(order)
    # conflicts << driver_conflict if driver_conflict

    # 3. メニュー重複検出
    menu_conflict = check_menu_duplication(order)
    conflicts << menu_conflict if menu_conflict

    # 4. 時間帯重複検出
    time_conflicts = check_time_overlap(order)
    conflicts.concat(time_conflicts)

    # 5. 定休日チェック
    closed_day_conflict = check_closed_day(order)
    conflicts << closed_day_conflict if closed_day_conflict

    conflicts
  end

  private

  # 飲食店キャパシティチェック
  def self.check_restaurant_capacity(order)
    return nil unless order.restaurant && order.scheduled_date && order.default_meal_count

    same_day_orders = Order.where(
      restaurant_id: order.restaurant_id,
      scheduled_date: order.scheduled_date
    ).where.not(id: order.id).where.not(status: 'cancelled')

    total_meal_count = same_day_orders.sum(:default_meal_count) + order.default_meal_count

    if order.restaurant.capacity_per_day && total_meal_count > order.restaurant.capacity_per_day
      {
        type: :capacity_over,
        severity: :high,
        message: "飲食店のキャパシティオーバー（合計#{total_meal_count}食 / 最大#{order.restaurant.capacity_per_day}食）",
        details: {
          total_meal_count: total_meal_count,
          capacity: order.restaurant.capacity_per_day,
          excess: total_meal_count - order.restaurant.capacity_per_day
        }
      }
    end
  end

  # メニュー重複検出
  def self.check_menu_duplication(order)
    return nil unless order.duplicate_menu_in_week?

    week_start = order.scheduled_date.beginning_of_week(:monday)
    week_end = order.scheduled_date.end_of_week(:monday)

    duplicate_orders = Order.where(
      restaurant_id: order.restaurant_id,
      menu_id: order.menu_id,
      scheduled_date: week_start..week_end
    ).where.not(id: order.id)

    {
      type: :menu_duplication,
      severity: :medium,
      message: "同じ週に同じメニューが重複しています",
      details: {
        duplicate_count: duplicate_orders.count,
        duplicate_orders: duplicate_orders.pluck(:id, :scheduled_date)
      }
    }
  end

  # 時間帯重複検出
  def self.check_time_overlap(order)
    conflicts = []
    return conflicts unless order.restaurant_id && order.collection_time && order.scheduled_date

    time_buffer = 2.hours
    start_time = order.collection_time - time_buffer
    end_time = order.collection_time + time_buffer

    similar_orders = Order.where(
      restaurant_id: order.restaurant_id,
      scheduled_date: order.scheduled_date
    ).where.not(id: order.id).where.not(status: 'cancelled')

    similar_orders.each do |other_order|
      next unless other_order.collection_time

      if other_order.collection_time.between?(start_time, end_time)
        conflicts << {
          type: :time_overlap,
          severity: :medium,
          message: "時間帯が重複しています（Order ##{other_order.id}: #{other_order.collection_time.strftime('%H:%M')}）",
          details: {
            other_order_id: other_order.id,
            other_time: other_order.collection_time,
            time_diff_minutes: ((order.collection_time - other_order.collection_time).abs / 60).to_i
          }
        }
      end
    end

    conflicts
  end

  # 定休日チェック
  def self.check_closed_day(order)
    return nil unless order.restaurant && order.scheduled_date

    day_of_week = order.scheduled_date.wday
    day_names = %w[sunday monday tuesday wednesday thursday friday saturday]
    day_name = day_names[day_of_week]

    if order.restaurant.closed_days&.include?(day_name)
      {
        type: :closed_day,
        severity: :high,
        message: "飲食店の定休日です（#{%w[日 月 火 水 木 金 土][day_of_week]}曜日）",
        details: {
          day_of_week: day_name,
          closed_days: order.restaurant.closed_days
        }
      }
    end
  end
end
