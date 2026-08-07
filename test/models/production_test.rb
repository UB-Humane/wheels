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
