import { Controller } from "@hotwired/stimulus"

// Window labels are rendered server-side in a specific zone, so changing the zone
// reloads the page with ?tz=. On first visit the browser's own zone is detected.
export default class extends Controller {
  static targets = ["select"]
  static values = { auto: Boolean }

  connect() {
    if (!this.autoValue || !this.hasSelectTarget) return

    const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!detected || detected === this.selectTarget.value) return

    const known = Array.from(this.selectTarget.options).some((option) => option.value === detected)
    if (!known) return

    this.selectTarget.value = detected
    this.reload()
  }

  reload() {
    const url = new URL(window.location.href)
    url.searchParams.set("tz", this.selectTarget.value)
    window.location.assign(url.toString())
  }
}
