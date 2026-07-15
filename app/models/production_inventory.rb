class ProductionInventory < ApplicationRecord
  belongs_to :production
  validates :helmets, :locks, numericality: { greater_than_or_equal_to: 0 }
end
