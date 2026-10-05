import { Controller } from '@hotwired/stimulus'

// Row action menus sit inside a horizontally scrolling table, which would clip an absolutely
// positioned menu. The menu is fixed instead, placed against its trigger, and closed on scroll.
export default class extends Controller {
  static targets = ['menu']

  connect() {
    this.close = this.close.bind(this)
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() { this.stopListening() }

  toggle() {
    if (!this.element.open) return this.stopListening()
    this.position()
    document.addEventListener('click', this.closeOnOutsideClick)
    document.addEventListener('keydown', this.closeOnEscape)
    window.addEventListener('scroll', this.close, true)
    window.addEventListener('resize', this.close)
  }

  position() {
    const trigger = this.element.querySelector('summary').getBoundingClientRect()
    const menu = this.menuTarget
    const below = trigger.bottom + 4
    const top = below + menu.offsetHeight > window.innerHeight ? trigger.top - 4 - menu.offsetHeight : below
    menu.style.margin = '0'
    menu.style.top = `${Math.max(8, top)}px`
    menu.style.left = `${Math.max(8, trigger.right - menu.offsetWidth)}px`
  }

  close() { this.element.open = false }

  closeOnOutsideClick(event) { if (!this.element.contains(event.target)) this.close() }

  closeOnEscape(event) {
    if (event.key !== 'Escape') return
    this.close()
    this.element.querySelector('summary').focus()
  }

  stopListening() {
    document.removeEventListener('click', this.closeOnOutsideClick)
    document.removeEventListener('keydown', this.closeOnEscape)
    window.removeEventListener('scroll', this.close, true)
    window.removeEventListener('resize', this.close)
  }
}
