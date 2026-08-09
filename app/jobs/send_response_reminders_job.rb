# frozen_string_literal: true

# Nudges people who have not responded while there is still time to.
class SendResponseRemindersJob < ApplicationJob
  queue_as :mailers

  REMIND_WITHIN = 48.hours

  def perform
    cycles = MatchCycle.where(status: :open).where(closes_at: Time.current..(Time.current + REMIND_WITHIN))
    sent = 0

    cycles.each do |cycle|
      sent += CycleInvitationService.new(cycle).deliver_reminders!.sent
    end

    Rails.logger.info("[WE Match] Queued #{sent} response reminder(s).")
    sent
  end
end
