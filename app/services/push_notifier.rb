class PushNotifier
  def self.notify(users:, title:, body:, url: "/")
    users.flat_map(&:push_subscriptions).each do |subscription|
      SendPushNotificationJob.perform_later(subscription, title, body, url)
    end
  end
end
