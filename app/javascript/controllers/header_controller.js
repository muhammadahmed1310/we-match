import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "nav", "toggle" ]

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  toggleMenu() {
    const expanded = this.navTarget.classList.toggle("site-nav--open")
    this.toggleTarget.setAttribute("aria-expanded", expanded)
    this.element.classList.toggle("site-header--menu-open", expanded)
  }

  onScroll() {
    this.element.classList.toggle("site-header--scrolled", window.scrollY > 8)
  }
}
