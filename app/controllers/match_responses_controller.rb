# frozen_string_literal: true

# Admin-side entry of a response on someone's behalf. Participants use
# ParticipantResponsesController and their private link instead.
class MatchResponsesController < ApplicationController
  before_action :set_match_cycle
  before_action :set_match_response, only: %i[edit update]
  before_action :load_form_data
  before_action :ensure_cycle_accepts_responses

  def new
    @match_response = @match_cycle.match_responses.new
  end

  def create
    @match_response = @match_cycle.match_responses.new(match_response_params)

    if @match_response.save
      mark_invitation_responded(@match_response)
      ResponseConfirmation.deliver!(@match_response)
      redirect_to @match_cycle, notice: "Response recorded."
    else
      @windows = windows_for(@match_response)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @match_response.update(match_response_params)
      mark_invitation_responded(@match_response)
      ResponseConfirmation.deliver!(@match_response)
      redirect_to @match_cycle, notice: "Response updated."
    else
      @windows = windows_for(@match_response)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_match_cycle
    @match_cycle = MatchCycle.includes(:group).find(params[:match_cycle_id])
  end

  def set_match_response
    @match_response = @match_cycle.match_responses.find(params[:id])
  end

  def load_form_data
    @members = @match_cycle.group.members.order(:name)
    @topics = @match_cycle.group.available_topics
    @windows = windows_for(@match_response)
  end

  def windows_for(match_response)
    MeetingWindows.new(@match_cycle, time_zone: match_response&.time_zone || "UTC")
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

  def mark_invitation_responded(match_response)
    @match_cycle.cycle_invitations.find_by(member_id: match_response.member_id)&.mark_responded!
  end

  def ensure_cycle_accepts_responses
    return unless @match_cycle.matched?

    redirect_to @match_cycle, alert: "This cycle is complete; responses cannot be changed."
  end
end
