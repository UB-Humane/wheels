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

  # Keys map to Google Fonts family names, loaded in the print windows via a Google Fonts
  # stylesheet link (see print_controller.js) rather than bundled with the app.
  PRINT_FONTS = {
    "inter" => "Inter",
    "noto_sans" => "Noto Sans",
    "ibm_plex_sans" => "IBM Plex Sans",
    "public_sans" => "Public Sans",
    "atkinson_hyperlegible" => "Atkinson Hyperlegible"
  }.freeze
  PRINT_FONT_DEFAULT = "atkinson_hyperlegible"

  store_attribute :settings, :print_font, :string, default: PRINT_FONT_DEFAULT
  define_method(:print_font) { super() || PRINT_FONT_DEFAULT }

  def print_font_family
    PRINT_FONTS.fetch(print_font, PRINT_FONTS.fetch(PRINT_FONT_DEFAULT))
  end

  validates :name, presence: true
  validates :print_padding_top, :print_padding_right, :print_padding_bottom, :print_padding_left,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :print_font, inclusion: { in: PRINT_FONTS.keys }
end
