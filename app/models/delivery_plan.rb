class DeliveryPlan < ApplicationRecord
  belongs_to :delivery_company
  belongs_to :driver, class_name: 'DeliveryUser', optional: true
  has_many :delivery_plan_items, -> { order(:sequence) }, dependent: :destroy
  has_many :delivery_plan_item_orders, through: :delivery_plan_items
  has_many :orders, through: :delivery_plan_item_orders

  STATUSES = ['draft', 'assigned_to_company', 'assigned_to_driver', 'in_progress', 'completed', 'cancelled'].freeze

  validates :delivery_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :on_date, ->(date) { where(delivery_date: date) }
  scope :for_company, ->(company_id) { where(delivery_company_id: company_id) }
  scope :for_driver, ->(driver_id) { where(driver_id: driver_id) }

  def self.ransackable_attributes(auth_object = nil)
    ["delivery_company_id", "driver_id", "delivery_date", "status", "started_at", "completed_at", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_company", "driver", "delivery_plan_items", "orders"]
  end

  # Orderから自動でDeliveryPlanItemsを生成
  def auto_generate_items_from_orders(order_ids)
    orders = Order.where(id: order_ids)

    # Order単位でバラバラに4つのアクションを生成
    orders.each_with_index do |order, index|
      base_sequence = delivery_plan_items.maximum(:sequence).to_i + 1 + (index * 4)

      # 1. ピック
      create_item_for_order(order, 'pickup', base_sequence, order.restaurant, 'Restaurant')

      # 2. 納品
      create_item_for_order(order, 'delivery', base_sequence + 1, order.company, 'Company')

      # 3. 回収
      create_item_for_order(order, 'collection', base_sequence + 2, order.company, 'Company')

      # 4. 返却
      create_item_for_order(order, 'return', base_sequence + 3, order.restaurant, 'Restaurant')
    end
  end

  private

  def create_item_for_order(order, action_role, sequence, location, location_type)
    item = delivery_plan_items.create!(
      sequence: sequence,
      action_type: action_role,
      location_type: location_type,
      location_id: location&.id,
      scheduled_time: estimate_time(action_role, order),
      meal_count: order.total_meal_count
    )

    item.delivery_plan_item_orders.create!(
      order_id: order.id,
      action_role: action_role
    )
  end

  def estimate_time(action_role, order)
    # TODO: 実際のロジックで時間を推定
    case action_role
    when 'pickup'
      '09:00'
    when 'delivery'
      '10:30'
    when 'collection'
      '13:00'
    when 'return'
      '15:00'
    end
  end
end
