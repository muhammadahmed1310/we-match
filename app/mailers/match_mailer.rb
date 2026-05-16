# frozen_string_literal: true

class MatchMailer < ApplicationMailer
  def introduction(match)
    @match = match
    @match_cycle = match.match_cycle
    @group = @match_cycle.group
    @member_one = match.member_one
    @member_two = match.member_two
    @responses = match.match_responses.includes(:member)

    mail(
      to: [ @member_one.email, @member_two.email ],
      subject: "WE Match: You're connected for a conversation in #{@group.name}"
    )
  end
end
