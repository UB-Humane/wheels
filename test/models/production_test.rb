require "test_helper"

class ProductionTest < ActiveSupport::TestCase
  test "valid production saves" do
    production = Production.new(name: "New Factory")
    assert production.valid?
  end

  test "name is required" do
    production = Production.new(name: nil)
    assert_not production.valid?
    assert_includes production.errors[:name], "can't be blank"
  end

  test "has_many user_productions" do
    production = productions(:main_production)
    assert_respond_to production, :user_productions
    assert production.user_productions.count >= 1
  end

  test "has_many users through user_productions" do
    production = productions(:main_production)
    assert_respond_to production, :users
    assert_includes production.users, users(:prod_admin)
  end

  test "has_many bike_requests" do
    production = productions(:main_production)
    assert_respond_to production, :bike_requests
    assert_includes production.bike_requests, bike_requests(:requested_bike)
  end

  test "print padding defaults when unset" do
    production = productions(:main_production)
    assert_equal 120, production.print_padding_top
    assert_equal 20, production.print_padding_right
    assert_equal 20, production.print_padding_bottom
    assert_equal 20, production.print_padding_left
  end

  test "print padding persists to settings" do
    production = productions(:main_production)
    production.update!(print_padding_top: 200, print_padding_right: 30, print_padding_bottom: 30, print_padding_left: 30)
    production.reload
    assert_equal 200, production.print_padding_top
    assert_equal 30, production.print_padding_right
    assert_equal 30, production.print_padding_bottom
    assert_equal 30, production.print_padding_left
  end

  test "negative print padding is invalid" do
    production = productions(:main_production)
    production.print_padding_top = -5
    assert_not production.valid?
    assert_includes production.errors[:print_padding_top], "must be greater than or equal to 0"
  end

  test "print font defaults to atkinson hyperlegible when unset" do
    production = productions(:main_production)
    assert_equal "atkinson_hyperlegible", production.print_font
    assert_equal "Atkinson Hyperlegible", production.print_font_family
  end

  test "print font persists to settings" do
    production = productions(:main_production)
    production.update!(print_font: "public_sans")
    production.reload
    assert_equal "public_sans", production.print_font
    assert_equal "Public Sans", production.print_font_family
  end

  test "unrecognized print font is invalid" do
    production = productions(:main_production)
    production.print_font = "comic_sans"
    assert_not production.valid?
    assert_includes production.errors[:print_font], "is not included in the list"
  end

  test "destroying production destroys associated bike_requests" do
    production = Production.create!(name: "Temp Production")
    dist = distributions(:downtown_dist)
    user = users(:dist_user)
    br = BikeRequest.new(
      due_date: Date.today + 7,
      distribution: dist,
      production: production,
      user: user
    )
    br.save!(validate: false)
    assert_difference "BikeRequest.count", -1 do
      production.destroy
    end
  end
end
