require "test_helper"

class PushNotifierTest < ActiveSupport::TestCase
  test "enqueues a job per subscription across all given users" do
    users = [ users(:prod_admin), users(:dist_user) ]

    assert_enqueued_jobs 2, only: SendPushNotificationJob do
      PushNotifier.notify(users: users, title: "Title", body: "Body")
    end
  end

  test "enqueues nothing for a user with no subscriptions" do
    assert_no_enqueued_jobs only: SendPushNotificationJob do
      PushNotifier.notify(users: [ users(:prod_volunteer) ], title: "Title", body: "Body")
    end
  end

  test "passes title, body, and url through to the job" do
    assert_enqueued_with(job: SendPushNotificationJob, args: [ push_subscriptions(:prod_admin_subscription), "Title", "Body", "/somewhere" ]) do
      PushNotifier.notify(users: [ users(:prod_admin) ], title: "Title", body: "Body", url: "/somewhere")
    end
  end
end
