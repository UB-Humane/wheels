class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(subscription, title, body, url)
    WebPush.payload_send(
      message: { title: title, body: body, url: url }.to_json,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh,
      auth: subscription.auth,
      vapid: {
        subject: "mailto:#{ENV.fetch('VAPID_CONTACT_EMAIL', 'admin@example.com')}",
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  end
end
