# frozen_string_literal: true

class MatchCycleMailer < ApplicationMailer
  def invitation(member, match_cycle)
    @member = member
    @match_cycle = match_cycle
    @group = match_cycle.group
    @response_url = new_match_cycle_match_response_url(match_cycle, member_id: member.id)

    mail(
      to: member.email,
      subject: "WE Match: Share your availability for #{@group.name}"
    )
  end
end
