# frozen_string_literal: true

class MatchCycleMailer < ApplicationMailer
  def invitation(cycle_invitation)
    @invitation = cycle_invitation
    @member = cycle_invitation.member
    @match_cycle = cycle_invitation.match_cycle
    @group = @match_cycle.group
    @response_url = cycle_invitation.response_url
    @closes_at = @match_cycle.closes_at
    @meeting_week = @match_cycle.meeting_week_range

    mail(
      to: @member.email,
      subject: "WE Match: Share your availability for #{@group.name}"
    )
  end

  def reminder(cycle_invitation)
    @invitation = cycle_invitation
    @member = cycle_invitation.member
    @match_cycle = cycle_invitation.match_cycle
    @group = @match_cycle.group
    @response_url = cycle_invitation.response_url
    @closes_at = @match_cycle.closes_at

    mail(
      to: @member.email,
      subject: "WE Match: A reminder to share your availability for #{@group.name}"
    )
  end

  def response_confirmation(match_response)
    @match_response = match_response
    @member = match_response.member
    @match_cycle = match_response.match_cycle
    @group = @match_cycle.group
    @topic = match_response.topic
    @window_labels = match_response.response_slots.map { |slot| slot.email_label(@member.time_zone) }
    invitation = @match_cycle.cycle_invitations.find_by(member_id: @member.id)
    @response_url = invitation&.response_url
    @can_edit = @match_cycle.accepting_responses?

    mail(
      to: @member.email,
      subject: "WE Match: We've recorded your availability for #{@group.name}"
    )
  end
end
