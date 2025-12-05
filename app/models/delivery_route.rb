class DeliveryRoute < ApplicationRecord
  # Associations
  belongs_to :delivery_assignment
  belongs_to :delivery_user

  # Validations
  validates :delivery_assignment_id, presence: true
  validates :delivery_user_id, presence: true
  validates :recorded_at, presence: true
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :speed, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :for_assignment, ->(assignment) { where(delivery_assignment: assignment) }
  scope :for_delivery_user, ->(user) { where(delivery_user: user) }
  scope :recent, -> { order(recorded_at: :desc) }
  scope :chronological, -> { order(recorded_at: :asc) }
  scope :today, -> { where('DATE(recorded_at) = ?', Date.current) }

  # Methods
  def coordinates
    [latitude.to_f, longitude.to_f]
  end

  def has_speed?
    speed.present? && speed > 0
  end

  def has_accuracy?
    accuracy.present?
  end

  def self.ransackable_attributes(auth_object = nil)
    ["accuracy", "created_at", "delivery_assignment_id", "delivery_user_id",
     "id", "latitude", "longitude", "recorded_at", "speed", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_assignment", "delivery_user"]
  end
end
