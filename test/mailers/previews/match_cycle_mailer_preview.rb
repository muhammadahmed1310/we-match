# frozen_string_literal: true

class MatchCycleMailerPreview < ActionMailer::Preview
  def invitation
    MatchCycleMailer.invitation(sample_invitation)
  end

  def reminder
    MatchCycleMailer.reminder(sample_invitation)
  end

  private

  def sample_invitation
    CycleInvitation.first || CycleInvitation.new(
      match_cycle: sample_cycle,
      member: Member.new(name: "Ava Chen", email: "ava@example.com", time_zone: "Asia/Singapore"),
      token: "preview-token"
    )
  end

  def sample_cycle
    MatchCycle.first || MatchCycle.new(
      group: Group.first || Group.new(name: "WE Fellows"),
      closes_at: 3.days.from_now,
      meeting_week_start: MatchCycle.default_meeting_week_start
    )
  end
end
