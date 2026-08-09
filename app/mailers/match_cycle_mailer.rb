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
end
