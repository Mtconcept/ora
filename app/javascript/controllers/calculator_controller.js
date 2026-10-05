import { Controller } from '@hotwired/stimulus'
export default class extends Controller {
  static targets = ['amount', 'range']
  range() { this.amountTarget.value = this.rangeTarget.value }
  number() { this.rangeTarget.value = this.amountTarget.value }
}
