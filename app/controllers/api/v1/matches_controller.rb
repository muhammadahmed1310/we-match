# frozen_string_literal: true

module Api
  module V1
    class MatchesController < BaseController
      before_action :set_match_cycle

      def index
        matches = @match_cycle.matches.includes(:member_one, :member_two)
        render json: matches.as_json(
          include: {
            member_one: { only: %i[id name email] },
            member_two: { only: %i[id name email] }
          }
        )
      end

      private

      def set_match_cycle
        @match_cycle = MatchCycle.find(params[:match_cycle_id])
      end
    end
  end
end
