import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() {
    const opening = this.panelTarget.hidden
    this.panelTarget.hidden = !opening
    this.buttonTarget.setAttribute("aria-expanded", String(opening))
  }

  close(event) {
    if (this.element.contains(event.target)) return
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
