class BikeRequest < ApplicationRecord
  MAX_BIKES = 15
  DELIVERY_STATUSES = %w[ready_for_delivery taken_up delivered]
  MECHANIC_STATUSES = %w[pending ready_for_delivery taken_up]

  belongs_to :distribution, optional: true
  belongs_to :production
  belongs_to :user
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :taker, class_name: "User", optional: true

  has_many :bikes, dependent: :destroy
  accepts_nested_attributes_for :bikes, allow_destroy: true

  enum :status, { pending: 0, requested: 1, ready_for_delivery: 2, delivered: 3, distributed: 4, denied: 5, archived: 6, taken_up: 7 }

  validates :phone, presence: true, format: { with: /\A\d{10}\z/, message: "must be exactly 10 digits" }
  validates :requestor_name, presence: true
  validates :due_date, presence: true
  validate :due_date_in_future, on: :create
  validate :owner_must_be_eligible

  def bikes_label_data
    bikes.map(&:label_data)
  end

  def overdue?
    due_date.present? && due_date < Date.today && (requested? || pending? || ready_for_delivery? || taken_up?)
  end

  private

  def due_date_in_future
    return unless due_date
    errors.add(:due_date, "must be in the future") if due_date <= Date.today
  end

  def owner_must_be_eligible
    return unless owner_id.present? && production.present?
    unless UserProduction.exists?(user_id: owner_id, production: production, role: UserProduction::OWNER_ROLES)
      errors.add(:owner, "must be a master mechanic or admin")
    end
  end
end
