class Restaurant < ApplicationRecord
  belongs_to :admin_user, optional: true
  has_many :menus
  has_many :orders
  has_many :supply_stocks, as: :location, dependent: :destroy
  has_many_attached :pickup_photos

  # 契約ステータスの選択肢
  CONTRACT_STATUSES = {
    'active' => '契約中',
    'pending' => '契約準備中',
    'suspended' => '一時停止',
    'terminated' => '契約終了'
  }.freeze

  # ジャンルの選択肢
  GENRES = [
    '和食',
    '洋食',
    '中華',
    'アジア',
    'カレー',
    '焼肉',
    'ラーメン',
    'スイーツ',
    'パン',
    'カフェ'
  ].freeze

  validates :name, presence: true
  validates :contract_status, presence: true
  validates :capacity_per_day, presence: true, numericality: { greater_than: 0 }

  def self.ransackable_attributes(auth_object = nil)
    ["contact_email", "contact_person", "contact_phone", "contract_status",
     "created_at", "genre", "id", "capacity_per_day", "name", "phone",
     "admin_user_id", "supplier_code", "updated_at", "default_pickup_time",
     "default_return_time", "pickup_notes", "pickup_building_info",
     "pickup_coordinates", "pickup_address"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["menus", "orders", "admin_user", "supply_stocks"]
  end
end
