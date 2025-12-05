class DeliveryAssignment < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :delivery_user
  belongs_to :delivery_company
  has_one :delivery_report, dependent: :destroy
  has_many :delivery_routes, dependent: :destroy

  # Validations
  validates :order_id, presence: true, uniqueness: true
  validates :delivery_user_id, presence: true
  validates :delivery_company_id, presence: true
  validates :scheduled_date, presence: true
  validates :status, inclusion: {
    in: %w[pending preparing in_transit completed failed],
    message: "%{value} is not a valid status"
  }

  # Scopes
  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_delivery_user, ->(user) { where(delivery_user: user) }
  scope :pending, -> { where(status: 'pending') }
  scope :preparing, -> { where(status: 'preparing') }
  scope :in_transit, -> { where(status: 'in_transit') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :active, -> { where(status: %w[pending preparing in_transit]) }
  scope :today, -> { where(scheduled_date: Date.current) }
  scope :upcoming, -> { where('scheduled_date >= ?', Date.current).order(scheduled_date: :asc, scheduled_time: :asc) }

  # Callbacks
  before_create :set_assigned_at
  before_update :track_status_changes

  # Status transition methods
  def start_preparing!
    return false unless status == 'pending'
    update(status: 'preparing')
  end

  def start_transit!
    return false unless status == 'preparing'
    update(status: 'in_transit')
  end

  def complete!
    return false unless status == 'in_transit'
    update(status: 'completed')
  end

  def mark_as_failed!
    update(status: 'failed')
  end

  # Query methods
  def can_start_preparing?
    status == 'pending'
  end

  def can_start_transit?
    status == 'preparing'
  end

  def can_complete?
    status == 'in_transit'
  end

  def active?
    %w[pending preparing in_transit].include?(status)
  end

  def finished?
    %w[completed failed].include?(status)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["assigned_at", "created_at", "delivery_company_id", "delivery_user_id",
     "id", "order_id", "scheduled_date", "scheduled_time", "sequence_number",
     "status", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_company", "delivery_report", "delivery_routes", "delivery_user", "order"]
  end

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end

  def track_status_changes
    if status_changed?
      Rails.logger.info "DeliveryAssignment ##{id}: status changed from #{status_was} to #{status}"
    end
  end
end
