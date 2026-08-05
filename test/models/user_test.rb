require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_user
    User.new(name: "Test User", email: "unique_#{SecureRandom.hex(4)}@example.com", password: "password")
  end

  # --- Validations ---

  test "valid user saves" do
    assert valid_user.valid?
  end

  test "name is required" do
    u = valid_user
    u.name = nil
    assert_not u.valid?
    assert_includes u.errors[:name], "can't be blank"
  end

  test "email is required" do
    u = valid_user
    u.email = nil
    assert_not u.valid?
    assert_includes u.errors[:email], "can't be blank"
  end

  test "email must be unique" do
    u = valid_user
    u.email = users(:prod_admin).email
    assert_not u.valid?
    assert_includes u.errors[:email], "has already been taken"
  end

  test "mobile_number is optional" do
    u = valid_user
    u.mobile_number = nil
    assert u.valid?
  end

  test "mobile_number accepts exactly 10 digits" do
    u = valid_user
    u.mobile_number = "5551234567"
    assert u.valid?
  end

  test "mobile_number rejects non-numeric characters" do
    u = valid_user
    u.mobile_number = "555-123-4567"
    assert_not u.valid?
    assert_includes u.errors[:mobile_number], "must be exactly 10 digits, no spaces or symbols"
  end

  test "mobile_number rejects a value that is too short" do
    u = valid_user
    u.mobile_number = "12345"
    assert_not u.valid?
    assert_includes u.errors[:mobile_number], "must be exactly 10 digits, no spaces or symbols"
  end

  test "mobile_number rejects a value that is too long" do
    u = valid_user
    u.mobile_number = "15551234567"
    assert_not u.valid?
    assert_includes u.errors[:mobile_number], "must be exactly 10 digits, no spaces or symbols"
  end

  test "has_secure_password authenticates correctly" do
    u = users(:prod_admin)
    assert u.authenticate("password")
    assert_not u.authenticate("wrong_password")
  end

  # --- Associations ---

  test "has_many user_productions" do
    u = users(:prod_admin)
    assert_respond_to u, :user_productions
    assert u.user_productions.any?
  end

  test "has_many productions through user_productions" do
    u = users(:prod_admin)
    assert_includes u.productions, productions(:main_production)
  end

  test "has_many user_distributions" do
    u = users(:dist_user)
    assert_respond_to u, :user_distributions
    assert u.user_distributions.any?
  end

  test "has_many distributions through user_distributions" do
    u = users(:dist_user)
    assert_includes u.distributions, distributions(:downtown_dist)
  end

  test "destroying user destroys user_productions" do
    u = User.create!(name: "Temp", email: "temp_up@example.com", password: "password")
    UserProduction.create!(user: u, production: productions(:main_production), role: "volunteer")
    assert_difference "UserProduction.count", -1 do
      u.destroy
    end
  end

  test "destroying user destroys user_distributions" do
    u = User.create!(name: "Temp", email: "temp_ud@example.com", password: "password")
    UserDistribution.create!(user: u, distribution: distributions(:downtown_dist), role: "volunteer")
    assert_difference "UserDistribution.count", -1 do
      u.destroy
    end
  end

  # --- all_locations ---

  test "all_locations returns empty array for user with no locations" do
    u = users(:no_location_user)
    assert_empty u.all_locations
  end

  test "all_locations returns only productions for production-only user" do
    u = users(:prod_admin)
    locations = u.all_locations
    assert_equal 1, locations.size
    assert_includes locations, productions(:main_production)
  end

  test "all_locations returns only distributions for distribution-only user" do
    u = users(:dist_user)
    locations = u.all_locations
    assert_equal 1, locations.size
    assert_includes locations, distributions(:downtown_dist)
  end

  test "all_locations returns both for multi-location user" do
    u = users(:multi_user)
    locations = u.all_locations
    assert_equal 2, locations.size
    assert_includes locations, productions(:main_production)
    assert_includes locations, distributions(:downtown_dist)
  end

  # --- single_location? ---

  test "single_location? is true for user with exactly one location" do
    assert users(:prod_admin).single_location?
    assert users(:dist_user).single_location?
  end

  test "single_location? is false for user with no locations" do
    assert_not users(:no_location_user).single_location?
  end

  test "single_location? is false for user with multiple locations" do
    assert_not users(:multi_user).single_location?
  end
end
