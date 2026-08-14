# PWA & Push Notifications

## Installability

- `public/manifest.webmanifest` — static JSON (`name`/`short_name` "Wheels", `start_url: "/"`, `display: "standalone"`, theme/background color, one SVG icon entry at `sizes: "any"`). Linked from `app/views/layouts/application.html.haml` via `<link rel="manifest">`, alongside a `theme-color` meta tag.
- `public/icon.svg` / `public/icon.png` — the app icon (blue wheel/spokes). `icon.png` (512×512) backs `apple-touch-icon`, since iOS Safari's home-screen icon support for SVG is inconsistent; `icon.svg` is the manifest's primary icon.
- `public/sw.js` — a plain top-level script, registered inline in the layout (`if ("serviceWorker" in navigator) navigator.serviceWorker.register("/sw.js")`). It can't live under `app/javascript/` or go through importmap — service workers are fetched as same-origin static scripts, not ES modules pulled through the import map. Scope is deliberately narrow: no offline caching or `fetch` interception (not needed here), just `install`/`activate` (`skipWaiting`/`clients.claim` so updates apply immediately) and the push-handling events below.

## Push subscriptions

`PushSubscription` (`app/models/push_subscription.rb`) — `belongs_to :user`, `endpoint`/`p256dh`/`auth` (all required, `endpoint` unique). `User has_many :push_subscriptions, dependent: :destroy` — a user can have several (one per device/browser they've enabled notifications on).

`resource :push_subscription, only: [:create, :destroy]` (singular, no `:id` — matches the existing `resource :profile`/`resource :mobile_number` pattern). `PushSubscriptionsController`:
- `create` — `current_user.push_subscriptions.find_or_initialize_by(endpoint:)`, upserting `p256dh`/`auth` from the browser's `PushSubscription.toJSON()` shape (`{ endpoint, keys: { p256dh, auth } }`). Idempotent for the same endpoint (re-subscribing on an already-subscribed device is a no-op, not an error).
- `destroy` — `current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy`. Scoped to `current_user` only, so a device can never unsubscribe another user's subscription, and looked up by `endpoint` (not a DB id) since that's what the browser itself knows about its own subscription.

## Opt-in UI

`/profile/edit` has a "Notifications" section (a single button, no separate preference model — having a `PushSubscription` row *is* the opt-in state). `app/javascript/controllers/push_controller.js`:
- `connect()` checks `navigator.serviceWorker.ready` → `registration.pushManager.getSubscription()` to reflect *this browser's* actual current state — the server has no way to know which stored subscription belongs to the device currently viewing the page.
- `toggle()` (button click, so `Notification.requestPermission()` has a user gesture behind it) subscribes via `pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: <VAPID public key> })` and POSTs the result to `push_subscription_path`, or unsubscribes and DELETEs, using the existing `csrf_meta_tags` token either way.

The VAPID public key is passed to the button via a data attribute, read from `ENV["VAPID_PUBLIC_KEY"]` directly (no initializer wrapper — matches how `ApplicationController.delivery_only_host` reads `ENV["APP_HOST"]`). See `docs/dev-environment.md` for how to generate a keypair.

## Sending a notification

`PushNotifier.notify(users:, title:, body:, url: "/")` (`app/services/push_notifier.rb`) is the single generic entry point — deliberately not tied to bike requests specifically, so any future feature can reuse it. It fans out over `users.flat_map(&:push_subscriptions)` and enqueues one `SendPushNotificationJob` per subscription.

`SendPushNotificationJob` calls `WebPush.payload_send` (the `web-push` gem) with the subscription's `endpoint`/`p256dh`/`auth` and the app's VAPID keys (`ENV["VAPID_PUBLIC_KEY"]`/`ENV["VAPID_PRIVATE_KEY"]`/`ENV["VAPID_CONTACT_EMAIL"]`). If the push service reports the subscription is gone (`WebPush::ExpiredSubscription`/`WebPush::InvalidSubscription` — e.g. the user uninstalled the app or cleared site data), the job destroys the `PushSubscription` itself rather than retrying forever.

`public/sw.js`'s `push` event shows the notification (`title`/`body`/`icon`, with the target `url` stashed in `event.notification.data`); `notificationclick` closes it and calls `clients.openWindow(url)`.

Where notifications actually fire from `BikeRequestsController` (which events, which recipients) is documented in `docs/architecture/locations.md`'s bike-request status-flow bullets, next to the transition it corresponds to.

## Background delivery (Solid Queue)

Push delivery is a real network call per subscription and shouldn't block the request/response cycle, so `PushNotifier`/`SendPushNotificationJob` go through Active Job (`config.active_job.queue_adapter = :solid_queue` in `config/environments/production.rb`; development/test use Rails' default `:async`/test adapters).

This app has one database (`config/database.yml` — no separate `queue`/`cache` entries), so Solid Queue's tables live in that same primary database rather than the separate `queue` database Rails' `solid_queue:install` generator assumes by default. If you ever re-run that generator, it will re-add `config.solid_queue.connects_to = { database: { writing: :queue } }` to `production.rb` and a `db/queue_schema.rb` — both need to be discarded (or the app breaks trying to connect to a database that doesn't exist) in favor of the actual migration at `db/migrate/*_create_solid_queue_tables.rb`.

`config/puma.rb` has `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]` — with that env var set (`docs/dev-environment.md`), the Solid Queue supervisor runs as a forked child of the same Puma process that serves web requests. This matches the app's single-container Dockerfile (`CMD ["./bin/thrust", "./bin/rails", "server"]`) — no separate worker service to deploy or scale.
