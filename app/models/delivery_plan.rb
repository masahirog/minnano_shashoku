class DeliveryPlan < ApplicationRecord
  belongs_to :delivery_company
  belongs_to :driver, optional: true
  has_many :delivery_plan_items, -> { order(Arel.sql('scheduled_time NULLS LAST, id')) }, dependent: :nullify
  has_many :orders, through: :delivery_plan_items

  STATUSES = ['draft', 'assigned_to_company', 'assigned_to_driver', 'in_progress', 'completed', 'cancelled'].freeze

  validates :delivery_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  before_destroy :unassign_items

  scope :on_date, ->(date) { where(delivery_date: date) }
  scope :for_company, ->(company_id) { where(delivery_company_id: company_id) }
  scope :for_driver, ->(driver_id) { where(driver_id: driver_id) }

  def self.ransackable_attributes(auth_object = nil)
    ["delivery_company_id", "driver_id", "delivery_date", "status", "started_at", "completed_at", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_company", "driver", "delivery_plan_items", "orders"]
  end

  # Orderの既存DeliveryPlanItemsをこのプランにアサイン
  def auto_generate_items_from_orders(order_ids)
    orders = Order.where(id: order_ids).includes(:delivery_plan_items)

    orders.each do |order|
      # Orderに紐づく4つのDeliveryPlanItemを取得
      items = order.delivery_plan_items.ordered

      items.each do |item|
        # このプランにアサイン（時刻は保持）
        item.update!(delivery_plan_id: self.id)
      end
    end
  end

  private

  # 削除前に紐づくDeliveryPlanItemsを未アサインに戻す
  def unassign_items
    # delivery_plan_items.update_all(delivery_plan_id: nil)
    # dependent: :nullify で自動的に処理されるため、明示的な処理は不要
    # ここでログを出力したい場合のみ実装
    Rails.logger.info "DeliveryPlan ##{id} を削除します。#{delivery_plan_items.count}件のアイテムを未アサインに戻します。"
  end
end
