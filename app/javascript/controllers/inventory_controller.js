import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { inventoryId: Number }

  addMany({ params: { item } }) {
    const input = window.prompt("How many to add?")
    if (input === null) return
    const qty = parseInt(input, 10)
    if (!qty || qty <= 0) return
    const form = document.createElement("form")
    form.method = "post"
    form.action = `/production_inventories/${this.inventoryIdValue}`
    ;[
      ["_method", "patch"],
      ["item", item],
      ["action_type", "add"],
      ["quantity", qty],
      ["authenticity_token", document.querySelector('meta[name="csrf-token"]').content]
    ].forEach(([name, value]) => {
      const inp = document.createElement("input")
      inp.type = "hidden"
      inp.name = name
      inp.value = value
      form.appendChild(inp)
    })
    document.body.appendChild(form)
    form.submit()
  }
}
