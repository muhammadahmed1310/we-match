# frozen_string_literal: true

module Api
  module V1
    class MatchResponsesController < BaseController
      before_action :set_match_cycle

      def create
        match_response = @match_cycle.match_responses.new(match_response_params)

        if match_response.save
          render json: payload(match_response), status: :created
        else
          render json: { errors: match_response.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        match_response = @match_cycle.match_responses.find(params[:id])

        if match_response.update(match_response_params)
          render json: payload(match_response)
        else
          render json: { errors: match_response.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_match_cycle
        @match_cycle = MatchCycle.find(params[:match_cycle_id])
      end

      def match_response_params
        params.require(:match_response).permit(
          :member_id,
          :topic_id,
          :topic_option_id,
          :topic_option_other,
          :time_zone,
          slot_selections: []
        )
      end

      def payload(match_response)
        {
          id: match_response.id,
          member_id: match_response.member_id,
          topic_id: match_response.topic_id,
          match_id: match_response.match_id,
          time_zone: match_response.time_zone,
          slots: match_response.response_slots.map { |slot| { starts_at: slot.starts_at, ends_at: slot.ends_at } }
        }
      end
    end
  end
end
