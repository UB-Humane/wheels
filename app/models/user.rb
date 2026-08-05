class User < ApplicationRecord
  has_secure_password

  has_many :user_productions, dependent: :destroy
  has_many :productions, through: :user_productions
  has_many :user_distributions, dependent: :destroy
  has_many :distributions, through: :user_distributions

  MOBILE_NUMBER_FORMAT = /\A\d{10}\z/

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :mobile_number, format: { with: MOBILE_NUMBER_FORMAT, message: "must be exactly 10 digits, no spaces or symbols" }, allow_blank: true

  def all_locations
    productions.to_a + distributions.to_a
  end

  def single_location?
    all_locations.size == 1
  end
end
