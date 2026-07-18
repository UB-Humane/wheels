class UserProduction < ApplicationRecord
  belongs_to :user
  belongs_to :production

  ROLES = %w[admin volunteer master_mechanic].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :production_id }

  def admin?           = role == "admin"
  def volunteer?       = role == "volunteer"
  def master_mechanic? = role == "master_mechanic"
end
