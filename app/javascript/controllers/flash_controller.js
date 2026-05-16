import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 6000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("flash--dismissing")
    this.element.addEventListener(
      "animationend",
      () => this.element.remove(),
      { once: true }
    )
  }
}
