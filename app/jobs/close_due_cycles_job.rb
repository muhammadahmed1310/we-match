# frozen_string_literal: true

# Honours closes_at. Without this the dates on a cycle are decoration.
class CloseDueCyclesJob < ApplicationJob
  queue_as :cycles

  def perform
    due = MatchCycle.where(status: :open).where(closes_at: ..Time.current)
    closed = due.to_a

    closed.each { |cycle| cycle.update!(status: :closed) }

    Rails.logger.info("[WE Match] Closed #{closed.size} cycle(s) whose response window ended.")
    closed
  end
end
