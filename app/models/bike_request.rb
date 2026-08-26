class BikeRequest < ApplicationRecord
  MAX_BIKES = 15
  DELIVERY_STATUSES = %w[ready_for_delivery taken_up delivered distributed]
  MECHANIC_STATUSES = %w[pending ready_for_delivery taken_up]
  CLOSED_STATUSES = %w[delivered distributed]
  CODENAME_ADJECTIVES = Rails.root.join("lib/data/adjectives.txt").readlines(chomp: true).freeze
  CODENAME_NOUNS = Rails.root.join("lib/data/nouns.txt").readlines(chomp: true).freeze

  belongs_to :distribution, optional: true
  belongs_to :production
  belongs_to :user
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :taker, class_name: "User", optional: true

  has_many :bikes, dependent: :destroy
  accepts_nested_attributes_for :bikes, allow_destroy: true

  enum :status, { pending: 0, requested: 1, ready_for_delivery: 2, delivered: 3, distributed: 4, denied: 5, archived: 6, taken_up: 7 }

  validates :due_date, presence: true
  validate :due_date_in_future, on: :create
  validate :owner_must_be_eligible

  before_create :assign_codename

  def self.generate_codename
    loop do
      codename = "#{CODENAME_ADJECTIVES.sample}-#{CODENAME_NOUNS.sample}"
      break codename unless where(codename: codename).where.not(status: CLOSED_STATUSES).exists?
    end
  end

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

  def assign_codename
    self.codename ||= self.class.generate_codename
  end
end
