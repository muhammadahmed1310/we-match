# frozen_string_literal: true

# A log of everything WE Match tried to send, so CMs can see what went out even
# when delivery is switched off and links are handed over manually.
class EmailDelivery < ApplicationRecord
  belongs_to :match_cycle, optional: true
  belongs_to :member, optional: true
  belongs_to :match, optional: true

  enum :status, { pending: 0, delivered: 1, failed: 2, skipped: 3 }, validate: true

  validates :mailer, :mailer_action, :recipients, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def recipient_list
    recipients.to_s.split(",").map(&:strip)
  end
end
