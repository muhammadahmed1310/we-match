# frozen_string_literal: true

# Julia's dropdown: the specific angle someone wants to explore inside a topic.
# Collected for aggregate insight only and never shown to the other person.
class TopicOption < ApplicationRecord
  belongs_to :topic
  # Deleting a chosen option would quietly erase the insight it was collected for, so
  # options that have been picked are kept and deactivated instead.
  has_many :match_responses, dependent: :restrict_with_error

  validates :label, presence: true, uniqueness: { scope: :topic_id, case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :label) }
end
