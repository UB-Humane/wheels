import { Controller } from "@hotwired/stimulus"

function urlBase64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - base64String.length % 4) % 4)
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
  const rawData = window.atob(base64)
  const outputArray = new Uint8Array(rawData.length)
  for (let i = 0; i < rawData.length; i++) outputArray[i] = rawData.charCodeAt(i)
  return outputArray
}

export default class extends Controller {
  static targets = ["button"]
  static values = { vapidPublicKey: String }

  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = "Notifications not supported on this device"
      return
    }
    navigator.serviceWorker.ready
      .then(registration => registration.pushManager.getSubscription())
      .then(subscription => this._setState(!!subscription))
  }

  toggle() {
    navigator.serviceWorker.ready
      .then(registration => registration.pushManager.getSubscription().then(subscription => ({ registration, subscription })))
      .then(({ registration, subscription }) => {
        if (subscription) {
          this._unsubscribe(subscription)
        } else {
          this._subscribe(registration)
        }
      })
  }

  _subscribe(registration) {
    Notification.requestPermission().then(permission => {
      if (permission !== "granted") return
      registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(this.vapidPublicKeyValue)
      }).then(subscription => {
        this._post("/push_subscription", "POST", { subscription: subscription.toJSON() })
          .then(() => this._setState(true))
      })
    })
  }

  _unsubscribe(subscription) {
    const endpoint = subscription.endpoint
    subscription.unsubscribe().then(() => {
      this._post("/push_subscription", "DELETE", { endpoint })
        .then(() => this._setState(false))
    })
  }

  _post(url, method, body) {
    const token = document.querySelector('meta[name="csrf-token"]').content
    return fetch(url, {
      method,
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify(body)
    })
  }

  _setState(subscribed) {
    this.buttonTarget.textContent = subscribed ? "Turn off notifications" : "Turn on notifications"
  }
}
