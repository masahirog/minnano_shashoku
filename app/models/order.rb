class Order < ApplicationRecord
  belongs_to :company
  belongs_to :restaurant, optional: true
  belongs_to :delivery_company, optional: true
  belongs_to :recurring_order, optional: true
  has_many :order_items, dependent: :destroy
  has_many :menus, through: :order_items
  has_many :delivery_sheet_items
  has_many :invoice_items
  has_one :delivery_assignment, dependent: :destroy
  has_many :delivery_plan_item_orders, dependent: :destroy
  has_many :delivery_plan_items, through: :delivery_plan_item_orders
  has_many :delivery_plans, through: :delivery_plan_items

  accepts_nested_attributes_for :order_items, allow_destroy: true

  ORDER_TYPES = ['定期', 'スポット', 'トライアル', '試食会'].freeze
  STATUSES = ['確認待ち', '確定', '準備中', '配送中', '完了'].freeze
  RESTAURANT_STATUSES = ['未確認', '確認済み', '調理中', '完成'].freeze
  DELIVERY_COMPANY_STATUSES = ['未配送', '配送準備', '配送中', '配送完了'].freeze

  validates :order_type, presence: true
  validates :scheduled_date, presence: true
  validates :status, presence: true

  # カスタムバリデーション
  validate :restaurant_capacity_check, if: -> { restaurant_id.present? && scheduled_date.present? && total_meal_count.present? }
  validate :restaurant_not_closed, if: -> { restaurant_id.present? && scheduled_date.present? }
  validate :delivery_time_feasible, if: -> { collection_time.present? && warehouse_pickup_time.present? }

  # コールバック
  before_save :calculate_totals

  def self.ransackable_attributes(auth_object = nil)
    ["company_id", "created_at", "total_meal_count",
     "delivery_company_id", "delivery_company_status",
     "id", "order_type", "restaurant_id",
     "restaurant_status", "scheduled_date", "status", "subtotal", "tax",
     "delivery_fee", "total_price", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["company", "delivery_company", "delivery_sheet_items", "invoice_items",
     "order_items", "menus", "restaurant", "delivery_plan_items", "delivery_plans"]
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

  # 後方互換性のための一時的なmenuメソッド
  # メニューが複数ある場合は最初のメニューを返す
  def menu
    menus.first
  end

  # 後方互換性のための一時的なdefault_meal_countメソッド
  def default_meal_count
    total_meal_count
  end

  # 同じ週に同じメニューが重複しているかチェック
  def duplicate_menu_in_week?
    return false unless scheduled_date && menus.any?

    monday = scheduled_date.beginning_of_week(:monday)
    sunday = scheduled_date.end_of_week(:monday)

    menu_ids = menus.pluck(:id)

    # 同じ週の他のOrderで同じメニューを使っているものを検索
    Order.joins(:order_items)
         .where(scheduled_date: monday..sunday)
         .where.not(id: id)
         .where.not(status: 'cancelled')
         .where(order_items: { menu_id: menu_ids })
         .exists?
  end

  private

  # 飲食店のキャパシティチェック
  def restaurant_capacity_check
    return unless restaurant && scheduled_date && total_meal_count

    # 同じ日の同じ飲食店の案件の合計食数を計算
    same_day_orders = Order.where(
      restaurant_id: restaurant_id,
      scheduled_date: scheduled_date
    ).where.not(id: id).where.not(status: 'cancelled')

    total_meals = same_day_orders.sum(:total_meal_count) + total_meal_count

    # capacity_per_dayをチェック
    if restaurant.capacity_per_day && total_meals > restaurant.capacity_per_day
      errors.add(:total_meal_count,
                 "この日の合計食数（#{total_meals}食）が飲食店のキャパシティ（#{restaurant.capacity_per_day}食）を超えています")
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

  # 合計を計算
  def calculate_totals
    self.total_meal_count = order_items.sum(:quantity)
    # 小計は整数に丸める
    self.subtotal = order_items.sum(:subtotal).to_f.round

    # 消費税を8%と10%に分けて計算
    calculate_tax_breakdown

    # 配送料も整数に丸める
    self.delivery_fee = (delivery_fee || 0).to_f.round

    # 配送料の消費税（10%）
    self.delivery_fee_tax = (delivery_fee.to_f * 0.1).round

    # 割引額: 手動入力がなければ自動計算（整数に丸める）
    if discount_amount.nil? || discount_amount.zero?
      apply_discounts
    else
      self.discount_amount = discount_amount.to_f.round
    end

    # 合計税額（互換性のため）
    self.tax = tax_8_percent.to_f + tax_10_percent.to_f + delivery_fee_tax.to_f

    # 合計金額も整数に丸める
    self.total_price = (subtotal.to_f + tax.to_f + delivery_fee.to_f - discount_amount.to_f).round
  end

  # 8%と10%の消費税を分けて計算
  def calculate_tax_breakdown
    subtotal_8 = 0
    subtotal_10 = 0

    order_items.each do |item|
      item_subtotal = item.subtotal.to_f

      if item.tax_rate.to_f == 8
        subtotal_8 += item_subtotal
      else
        subtotal_10 += item_subtotal
      end
    end

    # 8%の消費税（整数に丸める）
    self.tax_8_percent = (subtotal_8 * 0.08).round
    # 10%の消費税（整数に丸める）
    self.tax_10_percent = (subtotal_10 * 0.10).round
  end

  # 割引を適用
  def apply_discounts
    return unless company

    total_discount = 0

    # 1. メニュー割引キャンペーン
    if company.discount_amount.to_i > 0
      # キャンペーン終了日が設定されていない、または終了日が未来の場合
      if company.discount_campaign_end_date.nil? || company.discount_campaign_end_date >= scheduled_date
        total_discount += company.discount_amount.to_i
      end
    end

    # 2. 配送料割引キャンペーン
    if company.delivery_fee_discount.to_i > 0
      # キャンペーン終了日が設定されていない、または終了日が未来の場合
      if company.delivery_fee_campaign_end_date.nil? || company.delivery_fee_campaign_end_date >= scheduled_date
        total_discount += company.delivery_fee_discount.to_i
      end
    end

    self.discount_amount = total_discount
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
