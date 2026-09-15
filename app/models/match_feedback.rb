# frozen_string_literal: true

# One private feedback link per matched person. Sent after the two-week match
# period that starts on the cycle's meeting-week Monday.
class MatchFeedback < ApplicationRecord
  VALUE_LABELS = {
    1 => "Not valuable",
    2 => "Slightly valuable",
    3 => "Somewhat valuable",
    4 => "Valuable",
    5 => "Very valuable"
  }.freeze

  belongs_to :match
  belongs_to :member
  belongs_to :topic_option, optional: true

  before_validation :ensure_token

  validates :token, presence: true, uniqueness: true
  validates :member_id, uniqueness: { scope: :match_id }
  validates :value_for_time, inclusion: { in: VALUE_LABELS.keys }, allow_nil: true
  validate :member_belongs_to_match
  validate :topic_option_belongs_to_match_topic
  validate :answers_make_sense, on: :submit

  scope :pending_send, -> { where(sent_at: nil) }
  scope :submitted, -> { where.not(submitted_at: nil) }
  scope :unsubmitted, -> { where(submitted_at: nil) }

  def self.generate_token
    SecureRandom.urlsafe_base64(24)
  end

  def submitted?
    submitted_at.present?
  end

  def sent?
    sent_at.present?
  end

  def mark_sent!
    update!(sent_at: Time.current, send_count: send_count + 1)
  end

  def partner
    match.member_one_id == member_id ? match.member_two : match.member_one
  end

  def topic
    match.topic
  end

  def value_for_time_label
    VALUE_LABELS[value_for_time]
  end

  def insight_label
    topic_option&.label
  end

  def feedback_url
    Rails.application.routes.url_helpers.match_feedback_url(
      token: token,
      **Rails.application.config.action_mailer.default_url_options.to_h
    )
  end

  def feedback_path
    Rails.application.routes.url_helpers.match_feedback_path(token: token)
  end

  private

  def ensure_token
    self.token = self.class.generate_token if token.blank?
  end

  def member_belongs_to_match
    return if match.blank? || member_id.blank?
    return if match.member_ids.include?(member_id)

    errors.add(:member, "must be one of the people in this match")
  end

  def topic_option_belongs_to_match_topic
    return if topic_option.blank?
    return if match&.topic_id.present? && topic_option.topic_id == match.topic_id

    errors.add(:topic_option, "does not belong to the matched topic")
  end

  def answers_make_sense
    if did_meet.nil?
      errors.add(:did_meet, "please tell us whether you met")
      return
    end

    return unless did_meet?

    errors.add(:value_for_time, "please rate the value of the conversation") if value_for_time.blank?
  end
end
