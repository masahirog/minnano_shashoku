class DeliveryCompany < ApplicationRecord
  has_many :drivers
  has_many :orders
  has_many :delivery_users, dependent: :destroy
  has_many :delivery_assignments, dependent: :destroy

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["contact_person", "created_at", "email", "id", "is_active",
     "name", "phone", "updated_at", "api_enabled", "api_key"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["drivers", "orders", "delivery_users", "delivery_assignments"]
  end

  # ドライバー数を返す
  def drivers_count
    drivers.count
  end

  # 配送担当者数を返す
  def delivery_users_count
    delivery_users.active.count
  end

  # APIキー生成
  def generate_api_key!
    self.api_key = SecureRandom.hex(32)
    save!
  end
end
