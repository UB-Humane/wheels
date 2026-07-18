class Bike < ApplicationRecord
  belongs_to :bike_request

  TYPES = %w[male female kid].freeze
  enum :bike_type, { male: 1, female: 2, kid: 3 }, default: :male

  validates :age, presence: true, if: :kid?

  after_update :sync_request_status, if: :saved_change_to_completed?

  def label_data
    [ name.presence || "", bike_type.capitalize,
      age&.to_s || "", height.presence || "", notes.presence || "" ]
  end

  private

  def sync_request_status
    req = bike_request
    if req.requested? && req.bikes.all?(&:completed?)
      req.update_columns(status: BikeRequest.statuses[:completed])
    elsif req.completed? && !req.bikes.all?(&:completed?)
      req.update_columns(status: BikeRequest.statuses[:requested])
    end
  end
end
