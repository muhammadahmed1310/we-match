# frozen_string_literal: true

class MatchResponsesController < ApplicationController
  before_action :set_match_cycle
  before_action :set_match_response, only: %i[edit update]
  before_action :load_members, only: %i[new create edit update]
  before_action :ensure_cycle_accepts_responses, only: %i[new create edit update]

  def new
    member = @match_cycle.group.members.find_by(id: params[:member_id]) if params[:member_id].present?

    existing = member && @match_cycle.match_responses.find_by(member: member)
    if existing
      redirect_to edit_match_cycle_match_response_path(@match_cycle, existing),
                  notice: "You already submitted a response. You can update it below."
      return
    end

    @match_response = @match_cycle.match_responses.new(member: member)
  end

  def create
    @match_response = @match_cycle.match_responses.new(match_response_params)

    if @match_response.save
      redirect_to @match_cycle, notice: "Match response submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @match_response.update(match_response_params)
      redirect_to @match_cycle, notice: "Match response updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_match_cycle
    @match_cycle = MatchCycle.find(params[:match_cycle_id])
  end

  def set_match_response
    @match_response = @match_cycle.match_responses.find(params[:id])
  end

  def load_members
    @members = @match_cycle.group.members.order(:name)
  end

  def match_response_params
    params.require(:match_response).permit(
      :member_id,
      :topic,
      :availability_start,
      :availability_end
    )
  end

  def ensure_cycle_accepts_responses
    return unless @match_cycle.matched?

    redirect_to @match_cycle, alert: "This cycle is complete; responses cannot be changed."
  end
end
