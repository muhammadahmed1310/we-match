# frozen_string_literal: true

class MatchMailerPreview < ActionMailer::Preview
  def introduction
    match = Match.first
    return sample_match unless match

    MatchMailer.introduction(match)
  end

  private

  def sample_match
    member_one = Member.new(name: "Ava Chen", email: "ava@example.com")
    member_two = Member.new(name: "Brianna Lopez", email: "brianna@example.com")
    cycle = MatchCycle.new(group: Group.new(name: "Expedition Alumni"))
    match = Match.new(match_cycle: cycle, member_one: member_one, member_two: member_two)
    MatchMailer.introduction(match)
  end
end
