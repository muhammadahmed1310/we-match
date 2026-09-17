# frozen_string_literal: true

# One week after pairs are introduced, ask matched people how it went.
class SendMatchFeedbackRequestsJob < ApplicationJob
  queue_as :mailers

  PERIOD_DAYS = 7

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
              .where.not(matched_at: nil)
              .where("matched_at <= ?", (today - PERIOD_DAYS).end_of_day)
  end
end
