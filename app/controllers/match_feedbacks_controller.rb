# frozen_string_literal: true

# Post-match reflection. Identity comes from the feedback token in the URL.
class MatchFeedbacksController < ApplicationController
  allow_participant_access

  layout "minimal"

  before_action :set_feedback

  def edit
    return redirect_to match_feedback_confirmation_path(token: @feedback.token) if @feedback.submitted?
  end

  def update
    if @feedback.submitted?
      return redirect_to match_feedback_confirmation_path(token: @feedback.token)
    end

    @feedback.assign_attributes(feedback_params)
    @feedback.topic_option_id = nil unless ActiveModel::Type::Boolean.new.cast(@feedback.did_meet)
    @feedback.value_for_time = nil unless ActiveModel::Type::Boolean.new.cast(@feedback.did_meet)
    @feedback.submitted_at = Time.current

    if @feedback.save(context: :submit)
      redirect_to match_feedback_confirmation_path(token: @feedback.token)
    else
      @feedback.submitted_at = nil
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    return redirect_to match_feedback_path(token: @feedback.token) unless @feedback.submitted?
  end

  private

  def set_feedback
    @feedback = MatchFeedback.includes(:member, :topic_option, match: [ :topic, :member_one, :member_two, { match_cycle: :group } ])
                             .find_by(token: params[:token])

    return render :unknown_link, status: :not_found if @feedback.nil?

    @member = @feedback.member
    @partner = @feedback.partner
    @topic = @feedback.topic
    @group = @feedback.match.match_cycle.group
    @options = @topic&.selectable_options || []
  end

  def feedback_params
    params.require(:match_feedback).permit(:did_meet, :value_for_time, :topic_option_id)
  end
end
