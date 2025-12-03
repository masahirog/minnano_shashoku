class Order < ApplicationRecord
  belongs_to :company
  belongs_to :restaurant
  belongs_to :menu
  belongs_to :second_menu, class_name: 'Menu', optional: true
  belongs_to :delivery_company, optional: true
  belongs_to :recurring_order, optional: true
  has_many :delivery_sheet_items
  has_many :invoice_items

  validates :order_type, presence: true
  validates :scheduled_date, presence: true
  validates :default_meal_count, presence: true
  validates :status, presence: true

  # カスタムバリデーション
  validate :restaurant_capacity_check, if: -> { restaurant_id.present? && scheduled_date.present? && default_meal_count.present? }
  validate :restaurant_not_closed, if: -> { restaurant_id.present? && scheduled_date.present? }
  validate :delivery_time_feasible, if: -> { collection_time.present? && warehouse_pickup_time.present? }

  def self.ransackable_attributes(auth_object = nil)
    ["company_id", "confirmed_meal_count", "created_at", "default_meal_count",
     "delivery_company_id", "delivery_company_status", "delivery_group",
     "delivery_priority", "id", "menu_id", "order_type", "restaurant_id",
     "restaurant_status", "scheduled_date", "second_menu_id", "status", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["company", "delivery_company", "delivery_sheet_items", "invoice_items", "menu", "restaurant", "second_menu"]
  end

  # 同じ週に同じメニューが重複しているかチェック
  def duplicate_menu_in_week?
    return false unless scheduled_date && restaurant_id && menu_id

    # 週の開始（月曜日）と終了（日曜日）を計算
    week_start = scheduled_date.beginning_of_week(:monday)
    week_end = scheduled_date.end_of_week(:monday)

    # 同じ週内で、同じrestaurant_idとmenu_idを持つOrderがあるかチェック（自分自身を除く）
    Order.where(restaurant_id: restaurant_id, menu_id: menu_id)
         .where(scheduled_date: week_start..week_end)
         .where.not(id: id)
         .exists?
  end

  # スケジュールコンフリクトをチェック
  def schedule_conflicts
    conflicts = []
    return conflicts unless scheduled_date

    # 1. 同じ飲食店・同じ日・似た時間帯のOrderをチェック
    if restaurant_id && collection_time
      time_buffer = 2.hours
      start_time = collection_time - time_buffer
      end_time = collection_time + time_buffer

      similar_orders = Order.where(restaurant_id: restaurant_id, scheduled_date: scheduled_date)
                            .where.not(id: id)
                            .where.not(status: 'cancelled')

      similar_orders.each do |other_order|
        next unless other_order.collection_time

        if other_order.collection_time.between?(start_time, end_time)
          conflicts << {
            type: :restaurant_time_overlap,
            message: "同じ飲食店で近い時間帯に別の案件があります（Order ##{other_order.id}: #{other_order.collection_time.strftime('%H:%M')}）",
            other_order: other_order
          }
        end
      end
    end

    # 2. 同じ企業・同じ日に複数配送がある場合
    if company_id
      same_day_orders = Order.where(company_id: company_id, scheduled_date: scheduled_date)
                             .where.not(id: id)
                             .where.not(status: 'cancelled')

      if same_day_orders.exists?
        conflicts << {
          type: :multiple_deliveries_same_day,
          message: "同じ企業の同じ日に#{same_day_orders.count}件の配送があります",
          other_orders: same_day_orders
        }
      end
    end

    conflicts
  end

  # コンフリクトがあるかどうかを返す
  def has_conflicts?
    schedule_conflicts.any?
  end

  private

  # 飲食店のキャパシティチェック
  def restaurant_capacity_check
    return unless restaurant && scheduled_date && default_meal_count

    # 同じ日の同じ飲食店の案件の合計食数を計算
    same_day_orders = Order.where(
      restaurant_id: restaurant_id,
      scheduled_date: scheduled_date
    ).where.not(id: id).where.not(status: 'cancelled')

    total_meal_count = same_day_orders.sum(:default_meal_count) + default_meal_count

    # capacity_per_dayをチェック
    if restaurant.capacity_per_day && total_meal_count > restaurant.capacity_per_day
      errors.add(:default_meal_count,
                 "この日の合計食数（#{total_meal_count}食）が飲食店のキャパシティ（#{restaurant.capacity_per_day}食）を超えています")
    end

    # max_lots_per_dayをチェック（同じ日の案件数）
    if restaurant.max_lots_per_day
      total_orders = same_day_orders.count + 1
      if total_orders > restaurant.max_lots_per_day
        errors.add(:scheduled_date,
                   "この日の案件数（#{total_orders}件）が飲食店の1日の最大ロット数（#{restaurant.max_lots_per_day}件）を超えています")
      end
    end
  end

  # 定休日チェック
  def restaurant_not_closed
    return unless restaurant && scheduled_date

    # closed_days（配列）に曜日が含まれているかチェック
    day_of_week = scheduled_date.wday # 0=日曜, 1=月曜, ...
    day_names = %w[sunday monday tuesday wednesday thursday friday saturday]
    day_name = day_names[day_of_week]

    if restaurant.closed_days&.include?(day_name)
      errors.add(:scheduled_date,
                 "#{scheduled_date.strftime('%Y年%m月%d日')}（#{%w[日 月 火 水 木 金 土][day_of_week]}曜日）は飲食店の定休日です")
    end
  end

  # 配送時間の妥当性チェック
  def delivery_time_feasible
    return unless collection_time && warehouse_pickup_time

    # 倉庫集荷時刻が回収時刻よりも前である必要がある
    # Time型の比較なので、日付部分は無視される
    if warehouse_pickup_time >= collection_time
      errors.add(:warehouse_pickup_time,
                 "倉庫集荷時刻（#{warehouse_pickup_time.strftime('%H:%M')}）は飲食店回収時刻（#{collection_time.strftime('%H:%M')}）よりも前である必要があります")
    end

    # 最低でも30分の余裕が必要
    time_diff = (collection_time.hour * 60 + collection_time.min) - (warehouse_pickup_time.hour * 60 + warehouse_pickup_time.min)
    if time_diff < 30
      errors.add(:collection_time,
                 "倉庫集荷から飲食店回収まで最低30分の余裕が必要です（現在: #{time_diff}分）")
    end
  end
end
