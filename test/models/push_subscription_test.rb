require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  def valid_subscription
    PushSubscription.new(user: users(:prod_admin), endpoint: "https://push.example.com/new",
      p256dh: "key", auth: "secret")
  end

  test "valid subscription saves" do
    assert valid_subscription.valid?
  end

  test "endpoint is required" do
    s = valid_subscription
    s.endpoint = nil
    assert_not s.valid?
    assert_includes s.errors[:endpoint], "can't be blank"
  end

  test "endpoint must be unique" do
    s = valid_subscription
    s.endpoint = push_subscriptions(:prod_admin_subscription).endpoint
    assert_not s.valid?
    assert_includes s.errors[:endpoint], "has already been taken"
  end

  test "p256dh is required" do
    s = valid_subscription
    s.p256dh = nil
    assert_not s.valid?
    assert_includes s.errors[:p256dh], "can't be blank"
  end

  test "auth is required" do
    s = valid_subscription
    s.auth = nil
    assert_not s.valid?
    assert_includes s.errors[:auth], "can't be blank"
  end

  test "belongs to user" do
    s = push_subscriptions(:prod_admin_subscription)
    assert_equal users(:prod_admin), s.user
  end
end
