require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  def subscription_params(endpoint: "https://push.example.com/subscriptions/new-device")
    { subscription: { endpoint: endpoint, keys: { p256dh: "p256dh-value", auth: "auth-value" } } }
  end

  # --- create ---

  test "create requires authentication" do
    post push_subscription_path, params: subscription_params, as: :json
    assert_redirected_to login_path
  end

  test "create persists a subscription scoped to current_user" do
    login_as(users(:prod_volunteer))
    assert_difference "PushSubscription.count", 1 do
      post push_subscription_path, params: subscription_params, as: :json
    end
    assert_equal users(:prod_volunteer), PushSubscription.last.user
  end

  test "create is idempotent for the same endpoint" do
    login_as(users(:prod_admin))
    assert_no_difference "PushSubscription.count" do
      post push_subscription_path, params: subscription_params(endpoint: push_subscriptions(:prod_admin_subscription).endpoint), as: :json
    end
  end

  # --- destroy ---

  test "destroy requires authentication" do
    delete push_subscription_path, params: { endpoint: push_subscriptions(:prod_admin_subscription).endpoint }, as: :json
    assert_redirected_to login_path
  end

  test "destroy removes the current user's matching subscription" do
    login_as(users(:prod_admin))
    assert_difference "PushSubscription.count", -1 do
      delete push_subscription_path, params: { endpoint: push_subscriptions(:prod_admin_subscription).endpoint }, as: :json
    end
  end

  test "destroy never removes another user's subscription" do
    login_as(users(:prod_admin))
    assert_no_difference "PushSubscription.count" do
      delete push_subscription_path, params: { endpoint: push_subscriptions(:dist_user_subscription).endpoint }, as: :json
    end
    assert PushSubscription.exists?(push_subscriptions(:dist_user_subscription).id)
  end
end
