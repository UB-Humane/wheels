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

  test "age is required when bike_type is kid" do
    bike = Bike.new(bike_request: bike_requests(:requested_bike), bike_type: :kid, age: nil)
    assert_not bike.valid?
    assert_includes bike.errors[:age], "can't be blank"
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

  # --- sync_request_status ---

  test "completing the only bike on a request advances request to completed" do
    bike = bikes(:requested_bike_bike)
    assert bike.bike_request.requested?
    bike.update!(completed: true)
    assert bike.bike_request.reload.completed?
  end

  test "completing one of multiple bikes does not advance request" do
    req = bike_requests(:completed_bike)
    req.update_columns(status: BikeRequest.statuses[:requested])
    bikes(:completed_bike_bike_one).update_columns(completed: false)
    bikes(:completed_bike_bike_two).update_columns(completed: false)

    bikes(:completed_bike_bike_one).update!(completed: true)
    assert req.reload.requested?
  end

  test "uncompleting a bike on a completed request reverts request to requested" do
    bike = bikes(:completed_bike_bike_one)
    assert bike.bike_request.completed?
    bike.update!(completed: false)
    assert bike.bike_request.reload.requested?
  end

  test "sync does not fire when other attributes change" do
    bike = bikes(:requested_bike_bike)
    bike.update!(name: "Alice")
    assert bike.bike_request.reload.requested?
  end

  test "completing a bike on a delivered request does not change request status" do
    req = bike_requests(:completed_bike)
    req.update_columns(status: BikeRequest.statuses[:delivered])
    bikes(:completed_bike_bike_one).update_columns(completed: false)

    bikes(:completed_bike_bike_one).update!(completed: true)
    assert req.reload.delivered?
  end
end
