class PushSubscription < ApplicationRecord
  # Polymorphic association - can belong to DeliveryUser or AdminUser
  belongs_to :subscribable, polymorphic: true

  # Validations
  validates :subscribable_type, presence: true
  validates :subscribable_id, presence: true
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :for_delivery_users, -> { where(subscribable_type: 'DeliveryUser') }
  scope :for_admin_users, -> { where(subscribable_type: 'AdminUser') }

  # Methods
  def activate!
    update(is_active: true)
  end

  def deactivate!
    update(is_active: false)
  end

  def subscription_info
    {
      endpoint: endpoint,
      keys: {
        p256dh: p256dh_key,
        auth: auth_key
      }
    }
  end

  def self.ransackable_attributes(auth_object = nil)
    ["auth_key", "created_at", "endpoint", "id", "is_active",
     "p256dh_key", "subscribable_id", "subscribable_type",
     "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["subscribable"]
  end
end
