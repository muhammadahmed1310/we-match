# frozen_string_literal: true

# Public opt-out for invitation and reminder emails (no login).
class EmailPreferencesController < ApplicationController
  allow_participant_access

  layout "minimal"

  before_action :set_member

  def show
  end

  def unsubscribe
    @member.opt_out_of_cycle_emails!
    redirect_to email_preferences_path(token: params[:token]), notice: "You're opted out of WE Match invitations and reminders."
  end

  def resubscribe
    @member.opt_in_to_cycle_emails!
    redirect_to email_preferences_path(token: params[:token]), notice: "You're back on WE Match invitations and reminders."
  end

  private

  def set_member
    @member = Member.find_by_email_preferences_token(params[:token])
    return if @member.present?

    render :unknown_link, status: :not_found
  end
end
