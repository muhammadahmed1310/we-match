# frozen_string_literal: true

# Julia's dropdown: the specific angle someone explores inside a topic.
# Asked after the match in the feedback email, for aggregate insight only.
class TopicOption < ApplicationRecord
  belongs_to :topic
  # Deleting a chosen option would quietly erase the insight it was collected for, so
  # options that have been picked are kept and deactivated instead.
  has_many :match_responses, dependent: :restrict_with_error
  has_many :match_feedbacks, dependent: :restrict_with_error

  validates :label, presence: true, uniqueness: { scope: :topic_id, case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :label) }
end
