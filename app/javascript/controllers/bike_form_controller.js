import { Controller } from "@hotwired/stimulus"

const MIN_BIKES = 1

export default class extends Controller {
  static targets = ["tbody", "countInput"]
  static values  = { maxBikes: Number, rowIndex: Number, validateAge: Boolean }

  connect() {
    if (this.validateAgeValue)
      this.tbodyTarget.querySelectorAll("tr").forEach(r => this._checkAge(r))
    this._syncCountInput()
  }

  setCount() {
    let n = parseInt(this.countInputTarget.value, 10)
    if (isNaN(n)) n = MIN_BIKES
    n = Math.max(MIN_BIKES, Math.min(this.maxBikesValue, n))
    this.countInputTarget.value = n

    const current = this._countActive()
    if (n > current) {
      for (let i = current; i < n; i++) this._addRow()
    } else if (n < current) {
      this._removeTrailing(current - n)
    }
  }

  removeBike(event) {
    if (this._countActive() <= MIN_BIKES) return
    this._destroyRow(event.target.closest("tr"))
    this._syncCountInput()
  }

  validateAgeField(event) {
    this._checkAge(event.target.closest("tr"))
  }

  _addRow() {
    const tpl = document.getElementById("bike-row-template")
    const html = tpl.innerHTML.replace(/NEW_INDEX/g, this.rowIndexValue++)
    const tr = document.createElement("tr")
    tr.innerHTML = html
    this.tbodyTarget.appendChild(tr)
  }

  _removeTrailing(count) {
    const rows = Array.from(this.tbodyTarget.querySelectorAll("tr"))
      .filter(r => r.style.display !== "none")
    rows.slice(-count).forEach(r => this._destroyRow(r))
  }

  _destroyRow(row) {
    const destroy = row.querySelector(".destroy-field")
    if (destroy) {
      destroy.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
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

  _syncCountInput() {
    if (this.hasCountInputTarget) this.countInputTarget.value = this._countActive()
  }
}
