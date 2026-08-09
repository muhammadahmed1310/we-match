# frozen_string_literal: true

class MatchesController < ApplicationController
  before_action :set_match_cycle

  def index
    @matches = @match_cycle.matches.includes(:member_one, :member_two, :topic)

    respond_to do |format|
      format.html
      format.json do
        render json: @matches.as_json(
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

  private

  def set_match_cycle
    @match_cycle = MatchCycle.includes(:group).find(params[:match_cycle_id])
  end
end
