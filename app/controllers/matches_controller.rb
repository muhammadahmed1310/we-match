# frozen_string_literal: true

class MatchesController < ApplicationController
  before_action :set_match_cycle

  def index
    @matches = @match_cycle.matches.includes(:member_one, :member_two, :match_responses)

    respond_to do |format|
      format.html
      format.json do
        render json: @matches.as_json(
          include: {
            member_one: { only: %i[id name email] },
            member_two: { only: %i[id name email] },
            match_responses: { only: %i[id topic availability_start availability_end] }
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
