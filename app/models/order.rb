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
  has_many :delivery_plan_items, dependent: :destroy
  has_many :delivery_plans, through: :delivery_plan_items

  accepts_nested_attributes_for :order_items, allow_destroy: true

  ORDER_TYPES = ['定期', 'スポット', 'トライアル', '試食会'].freeze
  STATUSES = ['未完了', '完了', 'キャンセル'].freeze
  RESTAURANT_STATUSES = ['未確認', '確認済み', '調理中', '完成'].freeze
  DELIVERY_COMPANY_STATUSES = ['未配送', '配送準備', '配送中', '配送完了'].freeze

  validates :order_type, presence: true
  validates :scheduled_date, presence: true
  validates :status, presence: true

  # カスタムバリデーション
  validate :restaurant_capacity_check, if: -> { restaurant_id.present? && scheduled_date.present? && total_meal_count.present? }
  validate :restaurant_not_closed, if: -> { restaurant_id.present? && scheduled_date.present? }

  # コールバック
  before_save :calculate_totals
  after_save :ensure_delivery_plan_items

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

  # 回収時刻（delivery_plan_itemsから取得）
  def collection_time
    delivery_plan_items.find_by(action_type: 'collection')&.scheduled_time
  end

  # 倉庫集荷時刻（delivery_plan_itemsから取得）
  def warehouse_pickup_time
    delivery_plan_items.find { |item| item.action_type == 'pickup' && item.own_location_id.present? }&.scheduled_time
  end

  # 案件種別に応じた色を返す
  def order_type_color
    case order_type
    when '定期'
      '#2196f3'  # 青
    when 'スポット'
      '#ff9800'  # オレンジ
    when 'トライアル'
      '#4caf50'  # 緑
    when '試食会'
      '#9c27b0'  # 紫
    else
      '#2196f3'  # デフォルトは青
    end
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

    # 割引額: 未設定の場合は0
    self.discount_amount = (discount_amount || 0).to_f.round

    # 合計税額（互換性のため）
    self.tax = tax_8_percent.to_f + tax_10_percent.to_f + delivery_fee_tax.to_f

    # 合計金額も整数に丸める（案件レベルの割引を反映）
    self.total_price = (subtotal.to_f + tax.to_f + delivery_fee.to_f + delivery_fee_tax.to_f - discount_amount.to_f).round
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

  # Order作成時に4つのDeliveryPlanItemを自動生成
  def ensure_delivery_plan_items
    return unless restaurant_id.present? && company_id.present? && scheduled_date.present?

    # 基準日時を作成
    base_date = scheduled_date

    # 既存のDeliveryPlanItemsを取得
    existing_items = delivery_plan_items.reload

    # 各アクションタイプと対応する情報
    default_items = [
      { action_type: 'pickup', location_type: :restaurant, location_id: restaurant_id, time: '10:00' },
      { action_type: 'delivery', location_type: :company, location_id: company_id, time: '11:00' },
      { action_type: 'collection', location_type: :company, location_id: company_id, time: '13:00' },
      { action_type: 'return', location_type: :restaurant, location_id: restaurant_id, time: '15:00' }
    ]

    default_items.each do |item_config|
      existing_item = existing_items.find { |ei| ei.action_type == item_config[:action_type] }

      if existing_item
        # 既存アイテムがある場合、場所を更新
        location_attr = "#{item_config[:location_type]}_id"
        updates = { location_attr => item_config[:location_id] }

        # scheduled_timeがnilの場合、デフォルト時刻を設定
        if existing_item.scheduled_time.nil?
          updates[:scheduled_time] = Time.zone.parse("#{base_date} #{item_config[:time]}")
        end

        existing_item.update!(updates)
      else
        # 新規作成の場合、デフォルト時刻を設定
        scheduled_time = Time.zone.parse("#{base_date} #{item_config[:time]}")
        location_attr = "#{item_config[:location_type]}_id"

        delivery_plan_items.create!(
          action_type: item_config[:action_type],
          location_attr => item_config[:location_id],
          scheduled_time: scheduled_time,
          status: 'pending'
        )
      end
    end
  end
end
