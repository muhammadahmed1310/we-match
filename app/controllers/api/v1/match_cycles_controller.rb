# frozen_string_literal: true

module Api
  module V1
    class MatchCyclesController < BaseController
      before_action :set_match_cycle, only: %i[show run_matching]

      def show
        render json: @match_cycle.as_json(
          only: %i[id status opens_at closes_at matched_at meeting_week_start],
          methods: %i[response_rate]
        ).merge(
          group: @match_cycle.group.as_json(only: %i[id name]),
          match_responses: response_payload,
          matches: match_payload
        )
      end

      # Mirrors the guards the HTML controller applies, so the API cannot be used to
      # match a draft cycle or one with no responses.
      def run_matching
        if @match_cycle.matched?
          return render_json_error("Matching has already been run for this cycle.", status: :conflict)
        end

        unless @match_cycle.ready_for_matching?
          return render_json_error("Cycle must be open or closed before matching.")
        end

        if @match_cycle.match_responses.none?
          return render_json_error("No responses have been submitted for this cycle.")
        end

        result = MatchingService.new(@match_cycle).call

        render json: {
          matches: result.matches.as_json(only: %i[id member_one_id member_two_id topic_id matched_slot_starts_at]),
          unmatched_count: result.unmatched.size,
          repeat_pairs: result.repeat_pairs
        }, status: :ok
      rescue MatchingService::AlreadyMatchedError => e
        render_json_error(e.message, status: :conflict)
      end

      private

      def set_match_cycle
        @match_cycle = MatchCycle.find(params[:id])
      end

      # The topic option each person chose is insight data and is not exposed here.
      def response_payload
        @match_cycle.match_responses.includes(:member, :topic, :response_slots).map do |response|
          {
            id: response.id,
            member: response.member.as_json(only: %i[id name email time_zone]),
            topic: response.topic&.as_json(only: %i[id name]),
            match_id: response.match_id,
            slots: response.response_slots.map { |slot| { starts_at: slot.starts_at, ends_at: slot.ends_at } }
          }
        end
      end

      def match_payload
        @match_cycle.matches.includes(:member_one, :member_two, :topic).as_json(
          only: %i[id matched_slot_starts_at],
          include: {
            member_one: { only: %i[id name email] },
            member_two: { only: %i[id name email] },
            topic: { only: %i[id name] }
          }
        )
      end
    end
  end
end
