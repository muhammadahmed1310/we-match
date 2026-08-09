# frozen_string_literal: true

# Opens a cycle for every group flagged for automation, at most once a fortnight.
# The interval is enforced from the group's own last automatic open rather than the
# schedule, so a missed or replayed run cannot double up.
class OpenBiweeklyCyclesJob < ApplicationJob
  queue_as :cycles

  INTERVAL_DAYS = 13
  OPENS_AT_HOUR = 9
  CLOSES_AT_HOUR = 17
  RESPONSE_DAYS = 3

  def perform(reference_date = nil)
    today = reference_date ? Date.parse(reference_date.to_s) : Date.current
    opened = []

    Group.auto_cycling.includes(:members).find_each do |group|
      next unless due?(group, today)
      next if group.members.size < 2

      cycle = create_cycle(group, today)
      CycleInvitationService.new(cycle).deliver_invitations!
      group.update!(auto_cycle_last_opened_on: today)
      opened << cycle
    end

    Rails.logger.info("[WE Match] Opened #{opened.size} automatic cycle(s) on #{today}.")
    opened
  end

  private

  def due?(group, today)
    return false if group.match_cycles.where(status: %i[open closed]).exists?
    return true if group.auto_cycle_last_opened_on.blank?

    (today - group.auto_cycle_last_opened_on).to_i >= INTERVAL_DAYS
  end

  def create_cycle(group, today)
    opens_at = Time.utc(today.year, today.month, today.day, OPENS_AT_HOUR)
    closes_at = opens_at.advance(days: RESPONSE_DAYS).change(hour: CLOSES_AT_HOUR)

    group.match_cycles.create!(
      status: :draft,
      opens_at: opens_at,
      closes_at: closes_at,
      meeting_week_start: MatchCycle.default_meeting_week_start(today),
      auto_created: true
    )
  end
end
