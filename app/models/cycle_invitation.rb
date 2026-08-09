# frozen_string_literal: true

# One private link per person per cycle. Persisting the token (rather than signing
# a URL) is what makes resend, link export, and per-person response tracking work.
class CycleInvitation < ApplicationRecord
  belongs_to :match_cycle
  belongs_to :member

  before_validation :ensure_token

  validates :token, presence: true, uniqueness: true
  validates :member_id, uniqueness: { scope: :match_cycle_id }

  scope :responded, -> { where.not(responded_at: nil) }
  scope :pending, -> { where(responded_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  def self.generate_token
    SecureRandom.urlsafe_base64(24)
  end

  def responded?
    responded_at.present?
  end

  def sent?
    sent_at.present?
  end

  def match_response
    @match_response ||= match_cycle.match_responses.find_by(member_id: member_id)
  end

  def mark_sent!
    update!(sent_at: Time.current, send_count: send_count + 1)
  end

  def mark_responded!
    update!(responded_at: Time.current) unless responded?
  end

  def response_url
    Rails.application.routes.url_helpers.participant_response_url(
      token: token,
      **Rails.application.config.action_mailer.default_url_options.to_h
    )
  end

  def response_path
    Rails.application.routes.url_helpers.participant_response_path(token: token)
  end

  private

  def ensure_token
    self.token = self.class.generate_token if token.blank?
  end
end
