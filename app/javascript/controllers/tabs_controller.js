import { Controller } from '@hotwired/stimulus'

// ARIA tabs: click selects, arrow keys and Home/End move between tabs and select as they go.
export default class extends Controller {
  static targets = ['tab', 'panel']

  select(event) { this.activate(this.tabTargets.indexOf(event.currentTarget)) }

  key(event) {
    const last = this.tabTargets.length - 1
    const current = this.tabTargets.indexOf(event.currentTarget)
    const next = { ArrowRight: current + 1, ArrowLeft: current - 1, Home: 0, End: last }[event.key]
    if (next === undefined) return
    event.preventDefault()
    this.activate(next > last ? 0 : next < 0 ? last : next)
    this.tabTargets[this.current].focus()
  }

  activate(index) {
    this.current = index
    this.tabTargets.forEach((tab, i) => {
      tab.setAttribute('aria-selected', String(i === index))
      tab.tabIndex = i === index ? 0 : -1
    })
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== index })
  }
}
