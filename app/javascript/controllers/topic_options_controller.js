import { Controller } from "@hotwired/stimulus"

// Response form: show the open-text "details" field only for topics that collect it.
// Feedback form: show the Other free-text field only when the Other option is selected.
export default class extends Controller {
  static targets = ["topic", "details", "optionSelect", "otherField"]

  connect() {
    this.refresh()
  }

  refresh() {
    this.toggleDetails()
    this.toggleOther()
  }

  topicChanged() {
    this.toggleDetails()
  }

  optionChanged() {
    this.toggleOther()
  }

  toggleDetails() {
    if (!this.hasDetailsTarget || !this.hasTopicTarget) return

    const option = this.topicTarget.selectedOptions[0]
    const needsDetails = option?.dataset?.collectsDetails === "true"
    this.detailsTarget.hidden = !needsDetails

    const input = this.detailsTarget.querySelector("textarea, input")
    if (input && !needsDetails) input.value = ""
  }

  toggleOther() {
    if (!this.hasOtherFieldTarget || !this.hasOptionSelectTarget) return

    const option = this.optionSelectTarget.selectedOptions[0]
    const isOther = option?.dataset?.other === "true"
    this.otherFieldTarget.hidden = !isOther

    const input = this.otherFieldTarget.querySelector("textarea, input")
    if (input && !isOther) input.value = ""
  }
}
