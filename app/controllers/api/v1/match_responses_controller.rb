# frozen_string_literal: true

module Api
  module V1
    class MatchResponsesController < BaseController
      before_action :set_match_cycle

      def create
        response = @match_cycle.match_responses.new(match_response_params)

        if response.save
          render json: response, status: :created
        else
          render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        response = @match_cycle.match_responses.find(params[:id])

        if response.update(match_response_params)
          render json: response
        else
          render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_match_cycle
        @match_cycle = MatchCycle.find(params[:match_cycle_id])
      end

      def match_response_params
        params.require(:match_response).permit(
          :member_id,
          :topic,
          :availability_start,
          :availability_end
        )
      end
    end
  end
end
