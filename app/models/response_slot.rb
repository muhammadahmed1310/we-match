# frozen_string_literal: true

# A fixed 1-hour window, stored in UTC. Two people can only be matched when they
# picked the exact same window, so slots must always start on the hour.
class ResponseSlot < ApplicationRecord
  DURATION = 1.hour

  belongs_to :match_response

  before_validation :normalize_boundaries

  validates :starts_at, presence: true, uniqueness: { scope: :match_response_id }
  validates :ends_at, presence: true
  validate :starts_on_the_hour

  scope :ordered, -> { order(:starts_at) }

  def label(time_zone = "UTC")
    zone = ActiveSupport::TimeZone[time_zone.to_s] || ActiveSupport::TimeZone["UTC"]
    local_start = starts_at.in_time_zone(zone)

    "#{local_start.strftime('%a %b %-d, %H:%M')}–#{local_start.advance(hours: 1).strftime('%H:%M %Z')}"
  end

  # Fuller wording for outbound emails (easier when English is a second language).
  def email_label(time_zone = "UTC")
    zone = ActiveSupport::TimeZone[time_zone.to_s] || ActiveSupport::TimeZone["UTC"]
    local_start = starts_at.in_time_zone(zone)
    local_end = local_start.advance(hours: 1)

    "#{local_start.strftime('%A, %B %-d, %Y, %H:%M')}–#{local_end.strftime('%H:%M %Z')}"
  end

  def utc_label
    "#{starts_at.utc.strftime('%a %b %-d, %H:%M')}–#{ends_at.utc.strftime('%H:%M')} UTC"
  end

  private

  def normalize_boundaries
    return if starts_at.blank?

    self.starts_at = starts_at.change(min: 0, sec: 0, usec: 0)
    self.ends_at = starts_at + DURATION
  end

  def starts_on_the_hour
    return if starts_at.blank?

    errors.add(:starts_at, "must start on the hour") unless starts_at.min.zero? && starts_at.sec.zero?
  end
end
