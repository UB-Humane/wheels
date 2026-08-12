require "test_helper"

class BikeTest < ActiveSupport::TestCase
  # --- defaults and enum ---

  test "default bike_type is male" do
    bike = Bike.new(bike_request: bike_requests(:requested_bike))
    assert bike.male?
  end

  test "default completed is false" do
    bike = Bike.new(bike_request: bike_requests(:requested_bike))
    assert_not bike.completed
  end

  test "bike_type male is valid" do
    assert bikes(:requested_bike_bike).male?
  end

  test "age is not required for kid bike_type" do
    bike = Bike.new(bike_request: bike_requests(:requested_bike), bike_type: :kid, age: nil)
    assert bike.valid?
  end

  test "age is not required for non-kid types" do
    bike = Bike.new(bike_request: bike_requests(:requested_bike), bike_type: :male, age: nil)
    assert bike.valid?
  end

  test "bike_type female can be set" do
    bike = bikes(:requested_bike_bike)
    bike.bike_type = :female
    assert bike.female?
  end

  test "bike_type kid can be set" do
    bike = bikes(:requested_bike_bike)
    bike.bike_type = :kid
    assert bike.kid?
  end

  # --- associations ---

  test "belongs to bike_request" do
    bike = bikes(:requested_bike_bike)
    assert_equal bike_requests(:requested_bike), bike.bike_request
  end
end
