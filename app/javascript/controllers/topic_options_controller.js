import { Controller } from "@hotwired/stimulus"

// Shows the option dropdown that belongs to the chosen topic and disables the rest
// so only one topic_option_id is ever submitted.
export default class extends Controller {
  static targets = ["topic", "optionGroup", "optionSelect"]

  connect() {
    this.topicChanged()
  }

  topicChanged() {
    const selected = this.hasTopicTarget ? this.topicTarget.value : ""

    this.optionGroupTargets.forEach((group) => {
      const matches = group.dataset.topicId === selected
      group.hidden = !matches

      group.querySelectorAll("select").forEach((select) => {
        select.disabled = !matches
        if (!matches) select.value = ""
      })
    })
  }
}
