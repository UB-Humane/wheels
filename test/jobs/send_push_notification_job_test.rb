require "test_helper"

class SendPushNotificationJobTest < ActiveSupport::TestCase
  def stub_payload_send(implementation)
    original = WebPush.method(:payload_send)
    WebPush.define_singleton_method(:payload_send) { |**kwargs| implementation.call(**kwargs) }
    yield
  ensure
    WebPush.define_singleton_method(:payload_send, original)
  end

  test "sends the payload via WebPush with the subscription's keys" do
    subscription = push_subscriptions(:prod_admin_subscription)
    called_with = nil

    stub_payload_send(->(**kwargs) { called_with = kwargs }) do
      SendPushNotificationJob.perform_now(subscription, "Title", "Body", "/somewhere")
    end

    assert_equal subscription.endpoint, called_with[:endpoint]
    assert_equal subscription.p256dh, called_with[:p256dh]
    assert_equal subscription.auth, called_with[:auth]
    assert_equal({ "title" => "Title", "body" => "Body", "url" => "/somewhere" }, JSON.parse(called_with[:message]))
  end

  test "destroys the subscription when it has expired" do
    subscription = push_subscriptions(:prod_admin_subscription)

    stub_payload_send(->(**kwargs) { raise WebPush::ExpiredSubscription.new(Struct.new(:body).new("Gone"), "push.example.com") }) do
      SendPushNotificationJob.perform_now(subscription, "Title", "Body", "/")
    end

    assert_not PushSubscription.exists?(subscription.id)
  end

  test "destroys the subscription when it is invalid" do
    subscription = push_subscriptions(:prod_admin_subscription)

    stub_payload_send(->(**kwargs) { raise WebPush::InvalidSubscription.new(Struct.new(:body).new("Gone"), "push.example.com") }) do
      SendPushNotificationJob.perform_now(subscription, "Title", "Body", "/")
    end

    assert_not PushSubscription.exists?(subscription.id)
  end
end
