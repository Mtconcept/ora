import { Controller } from '@hotwired/stimulus'

// Live version of the affordability illustration: treatment budget = monthly budget × term ÷ 1.12.
export default class extends Controller {
  static targets = ['range', 'term', 'monthly', 'total', 'months', 'fill']

  connect() { this.render() }

  pick(event) {
    this.termTargets.forEach((button) => button.setAttribute('aria-pressed', String(button === event.currentTarget)))
    this.element.querySelector('input[name=term]').value = event.currentTarget.dataset.term
    this.render()
  }

  render() {
    const budget = Number(this.rangeTarget.value)
    const term = Number(this.element.querySelector('input[name=term]').value)
    const naira = (value) => '₦' + Math.floor(value).toLocaleString('en-NG')
    const min = Number(this.rangeTarget.min), max = Number(this.rangeTarget.max)
    this.monthlyTarget.textContent = naira(budget)
    this.totalTarget.textContent = naira(budget * term / 1.12)
    this.monthsTarget.textContent = `${term} months`
    this.fillTarget.style.width = `${((budget - min) / (max - min)) * 100}%`
  }
}
