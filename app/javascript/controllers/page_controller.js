import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content" ]

  connect() {
    this.animateIn()
    document.addEventListener("turbo:load", this.onTurboLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.onTurboLoad)
  }

  onTurboLoad = () => {
    this.animateIn()
  }

  animateIn() {
    const el = this.hasContentTarget ? this.contentTarget : this.element
    el.classList.remove("is-visible")
    requestAnimationFrame(() => {
      el.classList.add("is-visible")
    })
  }
}
