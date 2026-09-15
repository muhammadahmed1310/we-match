# frozen_string_literal: true

# Two weeks after each cycle's meeting-week Monday, ask matched people how it went.
class SendMatchFeedbackRequestsJob < ApplicationJob
  queue_as :mailers

  PERIOD_DAYS = 14

  def perform(reference_date = nil)
    today = reference_date ? Date.parse(reference_date.to_s) : Date.current
    sent = 0

    due_cycles(today).find_each do |cycle|
      sent += MatchFeedbackService.new(cycle).deliver_requests!.sent
    end

    Rails.logger.info("[WE Match] Queued #{sent} match feedback request(s) on #{today}.")
    sent
  end

  private

  def due_cycles(today)
    MatchCycle.matched
              .where.not(meeting_week_start: nil)
              .where("meeting_week_start <= ?", today - PERIOD_DAYS)
  end
end
