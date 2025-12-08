class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :companies
  has_many :restaurants
  has_one_attached :photo

  ROLES = ['管理者権限', '社員', 'パートスタッフ'].freeze

  validates :name, presence: true
  validates :employee_number, uniqueness: true, allow_nil: true
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  # ログイン可能なユーザーのみDevise認証をバイパス
  def active_for_authentication?
    super && is_login_enabled?
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "role", "phone", "employee_number",
     "is_login_enabled", "remember_created_at", "reset_password_sent_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["companies", "restaurants"]
  end
end
