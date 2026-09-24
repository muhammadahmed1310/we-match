import { Controller } from "@hotwired/stimulus"

// Searchable time zone combobox. Options stay IANA zones from the server
// (ActiveSupport / tz database — the same standard other apps use).
export default class extends Controller {
  static targets = ["select", "query", "list", "option", "clear"]
  static values = {
    auto: { type: Boolean, default: false },
    reload: { type: Boolean, default: false }
  }

  connect() {
    this.close()
    if (this.autoValue) this.detectBrowserZone()
    this.syncFromSelect()
  }

  detectBrowserZone() {
    if (!this.hasSelectTarget || this.selectTarget.value) return

    const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!detected) return

    const known = Array.from(this.selectTarget.options).some((option) => option.value === detected)
    if (!known) return

    this.selectTarget.value = detected
    this.syncFromSelect()
    if (this.reloadValue) this.reloadPage()
  }

  open() {
    this.filter()
    this.listTarget.hidden = false
  }

  close() {
    if (this.hasListTarget) this.listTarget.hidden = true
  }

  filter() {
    const needle = this.queryTarget.value.trim().toLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const match = !needle || option.dataset.search.includes(needle)
      option.hidden = !match
      if (match) visible += 1
    })

    this.listTarget.hidden = visible === 0
  }

  choose(event) {
    const option = event.currentTarget
    this.selectTarget.value = option.dataset.value
    this.queryTarget.value = option.dataset.label
    this.updateClearButton()
    this.close()
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))

    if (this.reloadValue) this.reloadPage()
  }

  clear(event) {
    event.preventDefault()
    event.stopPropagation()

    this.selectTarget.value = ""
    this.queryTarget.value = ""
    this.updateClearButton()
    this.close()
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.queryTarget.focus()
  }

  onQueryInput() {
    // Typing means they're searching — don't keep a stale hidden value.
    if (this.selectTarget.value) {
      const selected = this.selectTarget.selectedOptions[0]
      if (!selected || this.queryTarget.value !== selected.text) {
        this.selectTarget.value = ""
        this.updateClearButton()
      }
    }

    this.open()
    this.filter()
  }

  onQueryKeydown(event) {
    if (event.key === "Escape") {
      this.syncFromSelect()
      this.close()
      this.queryTarget.blur()
    }

    if (event.key === "Enter") {
      event.preventDefault()
      const first = this.optionTargets.find((option) => !option.hidden)
      if (first) first.click()
    }
  }

  onDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.syncFromSelect()
      this.close()
    }
  }

  syncFromSelect() {
    if (!this.hasQueryTarget || !this.hasSelectTarget) return

    const value = this.selectTarget.value
    const selected = this.selectTarget.selectedOptions[0]
    this.queryTarget.value = value && selected ? selected.text : ""
    this.updateClearButton()
  }

  updateClearButton() {
    if (!this.hasClearTarget) return

    const hasValue = Boolean(this.selectTarget.value)
    this.clearTarget.hidden = !hasValue
  }

  reloadPage() {
    const url = new URL(window.location.href)
    url.searchParams.set("tz", this.selectTarget.value)
    window.location.assign(url.toString())
  }
}
