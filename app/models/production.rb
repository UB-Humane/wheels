class Production < ApplicationRecord
  has_many :user_productions, dependent: :destroy
  has_many :users, through: :user_productions
  has_many :bike_requests, dependent: :destroy
  has_many :donors, dependent: :destroy
  has_one :inventory, class_name: "ProductionInventory", dependent: :destroy

  # Defaults here matter for records that predate a given key (e.g. added later without a migration
  # to backfill old rows) — store_attribute's own `default:` only applies to brand-new, unsaved
  # records, so a loaded row missing the key would otherwise read back nil instead of falling back.
  PRINT_PADDING_DEFAULTS = { top: 120, right: 20, bottom: 20, left: 20 }.freeze

  PRINT_PADDING_DEFAULTS.each do |side, default|
    store_attribute :settings, :"print_padding_#{side}", :integer, default: default

    define_method(:"print_padding_#{side}") { super() || default }
  end

  validates :name, presence: true
  validates :print_padding_top, :print_padding_right, :print_padding_bottom, :print_padding_left,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
