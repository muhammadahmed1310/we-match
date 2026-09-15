# frozen_string_literal: true

# The participant side of WE Match. Identity comes from the invitation token in the
# URL, so a person can only ever create or edit their own response — there is no
# member picker and no member_id in the params.
class ParticipantResponsesController < ApplicationController
  allow_participant_access

  layout "minimal"

  before_action :set_invitation
  before_action :set_match_response, only: %i[edit update]
  before_action :ensure_cycle_accepts_responses, only: %i[edit update]

  def edit
    @match_response.time_zone = detected_time_zone
    @windows = MeetingWindows.new(@match_cycle, time_zone: @match_response.time_zone)
  end

  def update
    @match_response.assign_attributes(match_response_params)

    if @match_response.save
      @invitation.mark_responded!
      redirect_to participant_response_confirmation_path(token: @invitation.token)
    else
      @windows = MeetingWindows.new(@match_cycle, time_zone: @match_response.time_zone)
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @match_response = @match_cycle.match_responses.includes(:topic, :response_slots).find_by(member_id: @invitation.member_id)

    return redirect_to participant_response_path(token: @invitation.token) if @match_response.nil?

    @can_edit = @match_cycle.accepting_responses?
  end

  private

  def set_invitation
    @invitation = CycleInvitation.includes(match_cycle: :group).find_by(token: params[:token])

    return render :unknown_link, status: :not_found if @invitation.nil?

    @match_cycle = @invitation.match_cycle
    @member = @invitation.member
    @group = @match_cycle.group
  end

  def set_match_response
    @match_response = @match_cycle.match_responses.find_by(member_id: @invitation.member_id) ||
                      @match_cycle.match_responses.new(member: @member)
    @topics = @group.available_topics
  end

  def ensure_cycle_accepts_responses
    return if @match_cycle.accepting_responses?

    render :closed, status: :ok
  end

  def match_response_params
    params.require(:match_response).permit(
      :topic_id,
      :topic_option_id,
      :topic_option_other,
      :time_zone,
      slot_selections: []
    )
  end

  def detected_time_zone
    candidate = params[:tz].presence || @match_response.time_zone
    ActiveSupport::TimeZone[candidate.to_s] ? candidate : "UTC"
  end
end
