import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    if (event.target.closest("a, button, input, select, textarea, summary, details, form, label")) return
    this.visit()
  }

  navigateWithKeyboard(event) {
    if (event.target !== this.element || !["Enter", " "].includes(event.key)) return
    event.preventDefault()
    this.visit()
  }

  visit() {
    if (window.Turbo) window.Turbo.visit(this.urlValue)
    else window.location.assign(this.urlValue)
  }
}
