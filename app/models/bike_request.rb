class BikeRequest < ApplicationRecord
  belongs_to :distribution, optional: true
  belongs_to :production
  belongs_to :user

  has_many :bikes, dependent: :destroy
  accepts_nested_attributes_for :bikes, allow_destroy: true

  enum :status, { pending: 0, requested: 1, ready_for_delivery: 2, delivered: 3, distributed: 4, denied: 5, archived: 6 }

  validates :phone, presence: true, format: { with: /\A\d{10}\z/, message: "must be exactly 10 digits" }
  validates :requestor_name, presence: true
  validates :due_date, presence: true
  validate :due_date_in_future, on: :create

  def bikes_label_data
    bikes.map(&:label_data)
  end

  private

  def due_date_in_future
    return unless due_date
    errors.add(:due_date, "must be in the future") if due_date <= Date.today
  end
end
