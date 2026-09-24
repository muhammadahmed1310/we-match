import { Controller } from "@hotwired/stimulus"

// Copy a signup URL into the clipboard and briefly confirm.
export default class extends Controller {
  static targets = ["input", "button"]
  static values = { text: String }

  async copy() {
    const value = this.hasInputTarget ? this.inputTarget.value : this.textValue
    if (!value) return

    try {
      await navigator.clipboard.writeText(value)
      this.flash("Copied")
    } catch (_error) {
      if (this.hasInputTarget) {
        this.inputTarget.select()
        this.flash("Press ⌘C / Ctrl+C")
      }
    }
  }

  flash(label) {
    if (!this.hasButtonTarget) return

    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = label
    window.setTimeout(() => {
      this.buttonTarget.textContent = original
    }, 1600)
  }
}
