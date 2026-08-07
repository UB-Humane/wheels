require "test_helper"

class DistributionTest < ActiveSupport::TestCase
  test "valid distribution saves" do
    distribution = Distribution.new(name: "New Center")
    assert distribution.valid?
  end

  test "name is required" do
    distribution = Distribution.new(name: nil)
    assert_not distribution.valid?
    assert_includes distribution.errors[:name], "can't be blank"
  end

  test "address is optional" do
    distribution = Distribution.new(name: "No Address Center")
    assert distribution.valid?
  end

  test "has_many user_distributions" do
    dist = distributions(:downtown_dist)
    assert_respond_to dist, :user_distributions
    assert dist.user_distributions.count >= 1
  end

  test "has_many users through user_distributions" do
    dist = distributions(:downtown_dist)
    assert_respond_to dist, :users
    assert_includes dist.users, users(:dist_user)
  end

  test "has_many bike_requests" do
    dist = distributions(:downtown_dist)
    assert_respond_to dist, :bike_requests
    assert_includes dist.bike_requests, bike_requests(:requested_bike)
  end

  test "destroying distribution destroys associated bike_requests" do
    dist = Distribution.create!(name: "Temp Dist")
    production = productions(:main_production)
    user = users(:dist_user)
    br = BikeRequest.new(
      due_date: Date.today + 7,
      distribution: dist,
      production: production,
      user: user
    )
    br.save!(validate: false)
    assert_difference "BikeRequest.count", -1 do
      dist.destroy
    end
  end
end
