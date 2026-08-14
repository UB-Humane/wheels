import { Controller } from "@hotwired/stimulus"

const DISMISSED_KEY = "wheels:installPromptDismissed"

export default class extends Controller {
  static targets = ["banner", "button"]

  connect() {
    this.deferredPrompt = null

    if (window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true) {
      this._setButtonState("Already installed on this device", true)
      return
    }

    if (!("onbeforeinstallprompt" in window)) {
      this._setButtonState("Add to home screen (not supported by this browser)", true)
      return
    }

    this._setButtonState("Add to home screen", true)
    window.addEventListener("beforeinstallprompt", this._handlePrompt)
    window.addEventListener("appinstalled", this._handleInstalled)
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this._handlePrompt)
    window.removeEventListener("appinstalled", this._handleInstalled)
  }

  install() {
    if (!this.deferredPrompt) return
    const prompt = this.deferredPrompt
    prompt.prompt()
    prompt.userChoice.finally(() => {
      this.deferredPrompt = null
      this._hideBanner()
      localStorage.setItem(DISMISSED_KEY, "1")
    })
  }

  dismiss() {
    this._hideBanner()
    localStorage.setItem(DISMISSED_KEY, "1")
  }

  _handlePrompt = (event) => {
    event.preventDefault()
    this.deferredPrompt = event
    this._setButtonState("Add to home screen", false)
    if (this.hasBannerTarget && !localStorage.getItem(DISMISSED_KEY)) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  _handleInstalled = () => {
    this.deferredPrompt = null
    this._setButtonState("Already installed on this device", true)
    this._hideBanner()
    localStorage.setItem(DISMISSED_KEY, "1")
  }

  _setButtonState(label, disabled) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.textContent = label
    this.buttonTarget.disabled = disabled
  }

  _hideBanner() {
    if (this.hasBannerTarget) this.bannerTarget.classList.add("hidden")
  }
}
