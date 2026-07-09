require "test_helper"

class BikeRequestTest < ActiveSupport::TestCase
  def valid_bike_request
    br = BikeRequest.new(
      phone: "5555550000",
      requestor_name: "Test Person",
      due_date: Date.today + 7,
      distribution: distributions(:downtown_dist),
      production: productions(:main_production),
      user: users(:dist_user)
    )
    br.bikes.build(bike_type: :any)
    br
  end

  test "valid bike request saves" do
    assert valid_bike_request.valid?
  end

  test "phone is required" do
    br = valid_bike_request
    br.phone = nil
    assert_not br.valid?
    assert_includes br.errors[:phone], "can't be blank"
  end

  test "phone must be exactly 10 digits" do
    br = valid_bike_request
    br.phone = "555-555-0000"
    assert_not br.valid?
    assert_includes br.errors[:phone], "must be exactly 10 digits"
  end

  test "phone with fewer than 10 digits is invalid" do
    br = valid_bike_request
    br.phone = "123456789"
    assert_not br.valid?
  end

  test "requestor_name is required" do
    br = valid_bike_request
    br.requestor_name = nil
    assert_not br.valid?
    assert_includes br.errors[:requestor_name], "can't be blank"
  end

  test "due_date is required" do
    br = valid_bike_request
    br.due_date = nil
    assert_not br.valid?
    assert_includes br.errors[:due_date], "can't be blank"
  end

  test "due_date must be in the future on create" do
    br = valid_bike_request
    br.due_date = Date.today
    assert_not br.valid?
    assert_includes br.errors[:due_date], "must be in the future"
  end

  test "due_date in past is invalid on create" do
    br = valid_bike_request
    br.due_date = Date.today - 1
    assert_not br.valid?
    assert_includes br.errors[:due_date], "must be in the future"
  end

  test "due_date validation skipped on update" do
    br = bike_requests(:requested_bike)
    br.due_date = Date.today - 1
    assert br.valid?
  end

  test "default status is requested" do
    br = valid_bike_request
    assert br.requested?
  end

  test "status transitions through all values" do
    br = bike_requests(:requested_bike)
    br.update!(status: :completed)
    assert br.completed?
    br.update!(status: :delivered)
    assert br.delivered?
    br.update!(status: :distributed)
    assert br.distributed?
  end

  test "belongs_to distribution" do
    br = bike_requests(:requested_bike)
    assert_equal distributions(:downtown_dist), br.distribution
  end

  test "belongs_to production" do
    br = bike_requests(:requested_bike)
    assert_equal productions(:main_production), br.production
  end

  test "belongs_to user" do
    br = bike_requests(:requested_bike)
    assert_equal users(:dist_user), br.user
  end

  test "has_many bikes" do
    br = bike_requests(:requested_bike)
    assert_respond_to br, :bikes
  end
end
