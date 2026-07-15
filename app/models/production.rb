class Production < ApplicationRecord
  has_many :user_productions, dependent: :destroy
  has_many :users, through: :user_productions
  has_many :bike_requests, dependent: :destroy
  has_one :inventory, class_name: "ProductionInventory", dependent: :destroy

  validates :name, presence: true
end
