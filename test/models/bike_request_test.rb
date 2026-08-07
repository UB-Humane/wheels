require "test_helper"

class BikeRequestTest < ActiveSupport::TestCase
  def valid_bike_request
    br = BikeRequest.new(
      due_date: Date.today + 7,
      distribution: distributions(:downtown_dist),
      production: productions(:main_production),
      user: users(:dist_user)
    )
    br.bikes.build(bike_type: :male)
    br
  end

  test "valid bike request saves" do
    assert valid_bike_request.valid?
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
    br.update!(status: :ready_for_delivery)
    assert br.ready_for_delivery?
    br.update!(status: :taken_up)
    assert br.taken_up?
    br.update!(status: :delivered)
    assert br.delivered?
    br.update!(status: :distributed)
    assert br.distributed?
  end

  test "owner can be a master mechanic" do
    br = valid_bike_request
    br.owner = users(:master_mechanic_user)
    assert br.valid?
  end

  test "owner can be an admin" do
    br = valid_bike_request
    br.owner = users(:prod_admin)
    assert br.valid?
  end

  test "owner cannot be a volunteer" do
    br = valid_bike_request
    br.owner = users(:prod_volunteer)
    assert_not br.valid?
    assert_includes br.errors[:owner], "must be a master mechanic or admin"
  end

  test "owner cannot be a user with no production role at all" do
    br = valid_bike_request
    br.owner = users(:no_location_user)
    assert_not br.valid?
    assert_includes br.errors[:owner], "must be a master mechanic or admin"
  end

  test "owner is optional" do
    br = valid_bike_request
    br.owner = nil
    assert br.valid?
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

  test "pending request with past due_date is overdue" do
    br = bike_requests(:pending_bike)
    br.update_column(:due_date, Date.today - 1)
    assert br.overdue?
  end

  test "ready_for_delivery request with past due_date is overdue" do
    br = bike_requests(:completed_bike)
    br.update_column(:due_date, Date.today - 1)
    assert br.overdue?
  end

  test "pending request with future due_date is not overdue" do
    br = bike_requests(:pending_bike)
    assert_not br.overdue?
  end

  test "requested request with past due_date is overdue" do
    br = bike_requests(:requested_bike)
    br.update_column(:due_date, Date.today - 1)
    assert br.overdue?
  end

  test "delivered request with past due_date is not overdue" do
    br = bike_requests(:pending_bike)
    br.update_column(:due_date, Date.today - 1)
    br.update!(status: :delivered)
    assert_not br.overdue?
  end

  test "denied request with past due_date is not overdue" do
    br = bike_requests(:denied_bike)
    br.update_column(:due_date, Date.today - 1)
    assert_not br.overdue?
  end

  test "archived request with past due_date is not overdue" do
    br = bike_requests(:archived_bike)
    br.update_column(:due_date, Date.today - 1)
    assert_not br.overdue?
  end

  test "pending request due today is not overdue" do
    br = bike_requests(:pending_bike)
    br.update_column(:due_date, Date.today)
    assert_not br.overdue?
  end

  test "taken_up request with past due_date is overdue" do
    br = bike_requests(:taken_up_bike)
    br.update_column(:due_date, Date.today - 1)
    assert br.overdue?
  end

  test "taken_up request with future due_date is not overdue" do
    br = bike_requests(:taken_up_bike)
    assert_not br.overdue?
  end
end
