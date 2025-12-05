class DeliveryReport < ApplicationRecord
  # Associations
  belongs_to :delivery_assignment
  belongs_to :delivery_user

  # ActiveStorage for photos
  # has_many_attached :photos # Will be configured when ActiveStorage is set up for photos

  # Validations
  validates :delivery_assignment_id, presence: true, uniqueness: true
  validates :delivery_user_id, presence: true
  validates :report_type, inclusion: {
    in: %w[completed failed issue],
    message: "%{value} is not a valid report type"
  }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :issue_type, inclusion: {
    in: %w[absent address_unknown damaged other],
    message: "%{value} is not a valid issue type"
  }, if: -> { report_type == 'issue' || report_type == 'failed' }

  # Scopes
  scope :completed, -> { where(report_type: 'completed') }
  scope :failed, -> { where(report_type: 'failed') }
  scope :issues, -> { where(report_type: 'issue') }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_date, ->(date) { where('DATE(completed_at) = ?', date) }
  scope :for_delivery_user, ->(user) { where(delivery_user: user) }

  # Methods
  def completed?
    report_type == 'completed'
  end

  def failed?
    report_type == 'failed'
  end

  def has_issue?
    report_type == 'issue'
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def has_photos?
    photos.present? && photos.is_a?(Array) && photos.any?
  end

  def delivery_duration
    return nil unless started_at.present? && completed_at.present?
    ((completed_at - started_at) / 60).round # in minutes
  end

  def self.ransackable_attributes(auth_object = nil)
    ["completed_at", "created_at", "delivery_assignment_id", "delivery_user_id",
     "id", "issue_type", "latitude", "longitude", "notes", "report_type",
     "started_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["delivery_assignment", "delivery_user"]
  end
end
