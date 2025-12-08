class DeliveryPlanItemOrder < ApplicationRecord
  belongs_to :delivery_plan_item
  belongs_to :order

  ACTION_ROLES = ['pickup', 'delivery', 'collection', 'return'].freeze

  validates :action_role, presence: true, inclusion: { in: ACTION_ROLES }
  validates :delivery_plan_item_id, uniqueness: { scope: :order_id }

  def self.ransackable_attributes(auth_object = nil)
    ["delivery_plan_item_id", "order_id", "action_role", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_plan_item", "order"]
  end
end
