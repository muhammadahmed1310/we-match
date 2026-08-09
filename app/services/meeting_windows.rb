# frozen_string_literal: true

# The set of fixed 1-hour windows a cycle offers, expressed in whatever time zone
# the person is answering from. Selections travel as "YYYY-MM-DD HH" local strings
# and are converted to UTC instants before they are stored, so two people in
# different zones who mean the same hour end up with identical slots.
class MeetingWindows
  FIRST_START_HOUR = 6
  LAST_START_HOUR = 21
  SELECTION_FORMAT = /\A(\d{4}-\d{2}-\d{2}) (\d{1,2})\z/

  attr_reader :match_cycle, :time_zone

  def initialize(match_cycle, time_zone: "UTC")
    @match_cycle = match_cycle
    @time_zone = ActiveSupport::TimeZone[time_zone.to_s] || ActiveSupport::TimeZone["UTC"]
  end

  def days
    week_start = match_cycle.meeting_week_start || MatchCycle.default_meeting_week_start
    (0..6).map { |offset| week_start + offset }
  end

  def hours
    (FIRST_START_HOUR..LAST_START_HOUR).to_a
  end

  # [[ "Monday, Aug 17", [[ "09:00–10:00", "2026-08-17 9" ], ... ]], ... ]
  def grouped_options
    days.map do |day|
      [
        day.strftime("%A, %b %-d"),
        hours.map { |hour| [ hour_label(hour), selection_key(day, hour) ] }
      ]
    end
  end

  def valid_selection?(selection)
    parse(selection).present?
  end

  def parse(selection)
    match = SELECTION_FORMAT.match(selection.to_s.strip)
    return nil if match.nil?

    day = Date.parse(match[1])
    hour = match[2].to_i
    return nil unless days.include?(day) && hours.include?(hour)

    time_zone.local(day.year, day.month, day.day, hour).utc
  rescue Date::Error
    nil
  end

  def selection_for(utc_time)
    return nil if utc_time.blank?

    local = utc_time.in_time_zone(time_zone)
    selection_key(local.to_date, local.hour)
  end

  def label_for(selection)
    starts_at = parse(selection)
    return selection.to_s if starts_at.nil?

    local = starts_at.in_time_zone(time_zone)
    "#{local.strftime('%a %b %-d, %H:%M')}–#{local.advance(hours: 1).strftime('%H:%M %Z')}"
  end

  private

  def selection_key(day, hour)
    "#{day.strftime('%Y-%m-%d')} #{hour}"
  end

  def hour_label(hour)
    format("%02d:00–%02d:00", hour, (hour + 1) % 24)
  end
end
