# frozen_string_literal: true

# Runs matching for closed cycles that automation opened. Cycles a CM created by
# hand are left alone so matching stays their decision.
class RunDueMatchingJob < ApplicationJob
  queue_as :cycles

  def perform
    cycles = MatchCycle.where(status: :closed, auto_created: true).includes(:group)
    results = []

    cycles.each do |cycle|
      if cycle.match_responses.none?
        Rails.logger.info("[WE Match] Cycle ##{cycle.id} (#{cycle.group.name}) had no responses; leaving it closed.")
        next
      end

      results << MatchingService.new(cycle).call
    rescue MatchingService::AlreadyMatchedError => e
      Rails.logger.warn("[WE Match] Cycle ##{cycle.id}: #{e.message}")
    end

    Rails.logger.info("[WE Match] Ran matching for #{results.size} cycle(s).")
    results
  end
end
