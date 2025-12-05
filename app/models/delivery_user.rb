class DeliveryUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  belongs_to :delivery_company
  has_many :delivery_assignments, dependent: :destroy
  has_many :delivery_reports, dependent: :destroy
  has_many :delivery_routes, dependent: :destroy
  has_many :push_subscriptions, as: :subscribable, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[admin driver], message: "%{value} is not a valid role" }
  validates :delivery_company, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :drivers, -> { where(role: 'driver') }
  scope :admins, -> { where(role: 'admin') }

  # Methods
  def active_for_authentication?
    super && is_active?
  end

  def inactive_message
    is_active? ? super : :account_inactive
  end

  def admin?
    role == 'admin'
  end

  def driver?
    role == 'driver'
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "phone", "role", "delivery_company_id", "is_active", "last_sign_in_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_company", "delivery_assignments", "delivery_reports", "delivery_routes"]
  end
end
