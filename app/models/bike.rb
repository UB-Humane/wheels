class Bike < ApplicationRecord
  belongs_to :bike_request

  TYPES = %w[male female kid].freeze
  enum :bike_type, { male: 1, female: 2, kid: 3 }, default: :male

  def label_data
    [ name.presence || "", bike_type.capitalize,
      age&.to_s || "", height.presence || "", notes.presence || "" ]
  end
end
