import { Controller } from '@hotwired/stimulus'

// Before/after slider: an invisible range input spans the image, so dragging, clicking and the
// arrow keys all move the divider through one --pos custom property.
export default class extends Controller {
  move(event) { this.element.style.setProperty('--pos', `${event.target.value}%`) }
}
