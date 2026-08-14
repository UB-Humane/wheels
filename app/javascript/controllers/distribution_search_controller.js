import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "dropdown", "button"]
  static values  = { productionId: Number }

  connect() {
    this._debounce = null
  }

  search() {
    clearTimeout(this._debounce)
    this.hiddenTarget.value = ""
    this._setButton(false)
    this._debounce = setTimeout(() => {
      const q = this.inputTarget.value.trim()
      if (!q) { this.dropdownTarget.hidden = true; return }
      fetch(`/productions/${this.productionIdValue}/distributions_search?q=${encodeURIComponent(q)}`)
        .then(r => r.json())
        .then(distributions => {
          this.dropdownTarget.innerHTML = ""
          if (!distributions.length) { this.dropdownTarget.hidden = true; return }
          distributions.forEach(d => {
            const li = document.createElement("li")
            li.textContent = d.name
            li.style.cssText = "padding:8px 12px;cursor:pointer;font-size:1.125rem;list-style:none"
            li.addEventListener("mouseenter", () => li.style.background = "#f3f4f6")
            li.addEventListener("mouseleave", () => li.style.background = "")
            li.addEventListener("click",      () => this._select(d))
            this.dropdownTarget.appendChild(li)
          })
          this.dropdownTarget.hidden = false
        })
    }, 200)
  }

  closeDropdown(event) {
    if (!this.element.contains(event.target)) this.dropdownTarget.hidden = true
  }

  _select(d) {
    this.hiddenTarget.value = d.id
    this.inputTarget.value  = d.name
    this.dropdownTarget.hidden = true
    this._setButton(true)
  }

  _setButton(enabled) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.disabled = !enabled
    this.buttonTarget.classList.toggle("opacity-50", !enabled)
    this.buttonTarget.classList.toggle("cursor-not-allowed", !enabled)
    this.buttonTarget.classList.toggle("cursor-pointer", enabled)
  }
}
