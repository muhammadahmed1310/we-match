# frozen_string_literal: true

class MatchCycleMailerPreview < ActionMailer::Preview
  def invitation
    member = Member.first || Member.new(name: "Ava Chen", email: "ava@example.com")
    cycle = MatchCycle.first || MatchCycle.new(group: Group.first || Group.new(name: "Expedition Alumni"))
    MatchCycleMailer.invitation(member, cycle)
  end
end
