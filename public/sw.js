self.addEventListener("install", event => {
  self.skipWaiting()
})

self.addEventListener("activate", event => {
  event.waitUntil(self.clients.claim())
})

self.addEventListener("push", event => {
  const data = event.data ? event.data.json() : {}
  const title = data.title || "Wheels"
  event.waitUntil(self.registration.showNotification(title, {
    body: data.body || "",
    icon: "/icon.png",
    data: { url: data.url || "/" }
  }))
})

self.addEventListener("notificationclick", event => {
  event.notification.close()
  const url = event.notification.data && event.notification.data.url ? event.notification.data.url : "/"
  event.waitUntil(self.clients.openWindow(url))
})
