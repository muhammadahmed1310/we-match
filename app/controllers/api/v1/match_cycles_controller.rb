# frozen_string_literal: true

module Api
  module V1
    class MatchCyclesController < BaseController
      before_action :set_match_cycle, only: %i[show run_matching]

      def show
        render json: @match_cycle.as_json(
          include: {
            group: { only: %i[id name] },
            match_responses: {
              only: %i[id member_id topic availability_start availability_end match_id],
              include: { member: { only: %i[id name email] } }
            },
            matches: {
              include: {
                member_one: { only: %i[id name email] },
                member_two: { only: %i[id name email] }
              }
            }
          }
        )
      end

      def run_matching
        result = MatchingService.new(@match_cycle).call
        render json: {
          matches: result.matches,
          unmatched_count: result.unmatched.size
        }, status: :ok
      rescue MatchingService::AlreadyMatchedError => e
        render_json_error(e.message)
      end

      private

      def set_match_cycle
        @match_cycle = MatchCycle.find(params[:id])
      end
    end
  end
end
