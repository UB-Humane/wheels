import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tbody", "addButton"]
  static values  = { maxBikes: Number, rowIndex: Number, validateAge: Boolean }

  connect() {
    if (this.validateAgeValue)
      this.tbodyTarget.querySelectorAll("tr").forEach(r => this._checkAge(r))
    this._updateAddBtn()
  }

  addBike() {
    const tpl = document.getElementById("bike-row-template")
    const html = tpl.innerHTML.replace(/NEW_INDEX/g, this.rowIndexValue++)
    const tr = document.createElement("tr")
    tr.innerHTML = html
    this.tbodyTarget.appendChild(tr)
    this._updateAddBtn()
  }

  removeBike(event) {
    const row = event.target.closest("tr")
    const destroy = row.querySelector(".destroy-field")
    if (destroy) {
      destroy.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
    this._updateAddBtn()
  }

  validateAgeField(event) {
    this._checkAge(event.target.closest("tr"))
  }

  _checkAge(row) {
    const sel = row.querySelector("select[name*='[bike_type]']")
    const age = row.querySelector("input[name*='[age]']")
    if (!sel || !age) return
    const isKid = sel.value === "kid"
    const num = parseInt(age.value)
    const invalid = isKid && (age.value === "" || num < 1 || num > 18)
    age.classList.toggle("border-red-600", invalid)
    age.classList.toggle("border-gray-400", !invalid)
  }

  _countActive() {
    return Array.from(this.tbodyTarget.querySelectorAll("tr"))
      .filter(r => r.style.display !== "none").length
  }

  _updateAddBtn() {
    const full = this._countActive() >= this.maxBikesValue
    this.addButtonTarget.disabled = full
    this.addButtonTarget.classList.toggle("opacity-50", full)
    this.addButtonTarget.classList.toggle("cursor-not-allowed", full)
  }
}
