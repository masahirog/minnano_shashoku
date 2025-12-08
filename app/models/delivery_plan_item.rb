class DeliveryPlanItem < ApplicationRecord
  belongs_to :delivery_plan
  belongs_to :location, polymorphic: true, optional: true
  has_many :delivery_plan_item_orders, dependent: :destroy
  has_many :orders, through: :delivery_plan_item_orders

  ACTION_TYPES = ['pickup', 'delivery', 'collection', 'return', 'supply_pickup', 'supply_return'].freeze
  STATUSES = ['pending', 'in_progress', 'completed', 'skipped'].freeze

  validates :sequence, presence: true
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :ordered, -> { order(:sequence) }
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }

  def self.ransackable_attributes(auth_object = nil)
    ["delivery_plan_id", "sequence", "action_type", "location_type", "location_id",
     "scheduled_time", "actual_time", "status", "meal_count", "completed_at", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_plan", "location", "orders"]
  end

  # 表示用のロケーション名
  def location_name
    location&.name || location_type
  end

  # アクションタイプの日本語表示
  def action_type_ja
    case action_type
    when 'pickup' then 'ピック'
    when 'delivery' then '納品'
    when 'collection' then '回収'
    when 'return' then '返却'
    when 'supply_pickup' then '備品ピック'
    when 'supply_return' then '備品返却'
    else action_type
    end
  end

  # ステータスの日本語表示
  def status_ja
    case status
    when 'pending' then '未完了'
    when 'in_progress' then '進行中'
    when 'completed' then '完了'
    when 'skipped' then 'スキップ'
    else status
    end
  end
end
