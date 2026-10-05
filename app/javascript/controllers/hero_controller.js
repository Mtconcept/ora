import { Controller } from '@hotwired/stimulus'

// The landing hero: a row of treatments whose progress bars hand the headline from one to the next,
// over a background that crossfades between clinic videos. The bar's CSS animation is the timer; its
// animationend moves on. Each option names a scene, and the next scene only fades in once its video
// can play, so a crossfade never passes through a blank frame. Hovering or focusing the row holds it,
// and the toggle pauses both video and rotation.
export default class extends Controller {
  static targets = ['scene', 'phrase', 'option', 'toggle']
  static fadeMs = 1400

  connect() {
    this.index = 0
    this.scene = this.activeScene()?.dataset.scene
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) this.setPaused(true)
  }

  disconnect() { clearTimeout(this.settle) }

  next(event) {
    if (!event.target.closest('.lp-rotator__bar')) return
    this.show((this.index + 1) % this.optionTargets.length)
  }

  pick(event) { this.show(this.optionTargets.indexOf(event.currentTarget)) }
  hold() { this.element.classList.add('is-holding') }
  release() { this.element.classList.remove('is-holding') }
  toggle() { this.setPaused(!this.paused) }

  show(index) {
    if (index === this.index || index < 0) return
    this.optionTargets[this.index].classList.remove('is-active')
    const option = this.optionTargets[index]
    void option.offsetWidth
    option.classList.add('is-active')
    this.phraseTargets.forEach((phrase, i) => phrase.classList.toggle('is-active', i === index))
    this.index = index
    this.crossfade(option.dataset.scene)
  }

  crossfade(name) {
    const next = this.sceneTargets.find((scene) => scene.dataset.scene === name)
    if (!next || name === this.scene) return
    this.scene = name
    const video = next.querySelector('video')
    video.currentTime = 0
    if (!this.paused) video.play().catch(() => {})

    const reveal = () => {
      if (this.scene !== name || next.classList.contains('is-active')) return
      this.sceneTargets.forEach((scene) => scene.classList.toggle('is-active', scene === next))
      clearTimeout(this.settle)
      this.settle = setTimeout(() => {
        this.sceneTargets.forEach((scene) => { if (scene !== next) scene.querySelector('video').pause() })
      }, this.constructor.fadeMs)
    }
    if (video.readyState >= 3) return reveal()
    video.addEventListener('canplay', reveal, { once: true })
    setTimeout(reveal, 2500)
  }

  get paused() { return this.element.classList.contains('is-paused') }

  activeScene() { return this.sceneTargets.find((scene) => scene.classList.contains('is-active')) }

  setPaused(paused) {
    this.element.classList.toggle('is-paused', paused)
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-pressed', String(paused))
      this.toggleTarget.setAttribute('aria-label', paused ? 'Play the video and rotating treatments' : 'Pause the video and rotating treatments')
    }
    const video = this.activeScene()?.querySelector('video')
    if (!video) return
    if (paused) video.pause()
    else video.play().catch(() => {})
  }
}
