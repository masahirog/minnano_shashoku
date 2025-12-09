class DeliveryPlanItem < ApplicationRecord
  belongs_to :delivery_plan, optional: true
  belongs_to :order
  belongs_to :restaurant, optional: true
  belongs_to :company, optional: true
  belongs_to :own_location, optional: true

  ACTION_TYPES = ['pickup', 'delivery', 'collection', 'return', 'supply_pickup', 'supply_return'].freeze
  STATUSES = ['pending', 'in_progress', 'completed', 'skipped'].freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :exactly_one_location

  scope :ordered, -> { order(Arel.sql('scheduled_time NULLS LAST, id')) }
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }

  def self.ransackable_attributes(auth_object = nil)
    ["delivery_plan_id", "action_type", "restaurant_id", "company_id", "own_location_id",
     "scheduled_time", "actual_time", "status", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_plan", "restaurant", "company", "own_location", "order"]
  end

  # 表示用のロケーション名
  def location_name
    restaurant&.name || company&.name || own_location&.name || '未設定'
  end

  # 場所オブジェクトを取得
  def location
    restaurant || company || own_location
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

  private

  # 3つの場所IDのうち、ちょうど1つだけが設定されていることを検証
  def exactly_one_location
    location_count = [restaurant_id, company_id, own_location_id].compact.size
    if location_count == 0
      errors.add(:base, '場所を1つ選択してください')
    elsif location_count > 1
      errors.add(:base, '場所は1つだけ選択してください')
    end
  end
end
