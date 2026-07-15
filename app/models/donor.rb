class Donor < ApplicationRecord
  belongs_to :production

  validates :first_name, :last_name, presence: true

  scope :active,   -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def full_name
    "#{first_name} #{last_name}"
  end
end
