import { Controller } from '@hotwired/stimulus'

// The header floats over the home hero in white, then settles onto a light bar once the hero has scrolled past.
// Pages without a hero keep the light bar throughout.
export default class extends Controller {
  connect() {
    this.update = this.update.bind(this)
    window.addEventListener('scroll', this.update, { passive: true })
    this.update()
  }
  disconnect() { window.removeEventListener('scroll', this.update) }
  update() {
    const hero = document.querySelector('.lp-hero')
    if (!hero) return this.element.classList.add('is-scrolled')
    const edge = hero.offsetHeight - this.element.offsetHeight
    this.element.classList.toggle('is-scrolled', window.scrollY > edge)
  }
}
