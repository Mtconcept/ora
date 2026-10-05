import { Controller } from '@hotwired/stimulus'
export default class extends Controller {
  static targets = ['menu', 'button']
  toggle() { this.menuTarget.hidden = !this.menuTarget.hidden; this.buttonTarget.setAttribute('aria-expanded', String(!this.menuTarget.hidden)) }
}
