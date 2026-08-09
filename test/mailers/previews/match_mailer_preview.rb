# frozen_string_literal: true

class MatchMailerPreview < ActionMailer::Preview
  def introduction
    MatchMailer.introduction(Match.first || sample_match)
  end

  private

  def sample_match
    member_one = Member.new(name: "Ava Chen", email: "ava@example.com", time_zone: "Asia/Singapore")
    member_two = Member.new(name: "Brianna Lopez", email: "brianna@example.com", time_zone: "America/New_York")
    cycle = MatchCycle.new(group: Group.new(name: "WE Fellows"))

    Match.new(
      match_cycle: cycle,
      member_one: member_one,
      member_two: member_two,
      topic: Topic.new(name: "Leadership"),
      matched_slot_starts_at: MatchCycle.default_meeting_week_start.to_time(:utc).change(hour: 13)
    )
  end
end
