# frozen_string_literal: true

class MatchCycleMailerPreview < ActionMailer::Preview
  def invitation
    MatchCycleMailer.invitation(sample_invitation)
  end

  def reminder
    MatchCycleMailer.reminder(sample_invitation)
  end

  def response_confirmation
    MatchCycleMailer.response_confirmation(sample_response)
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

  def sample_response
    existing = MatchResponse.includes(:topic, :response_slots, :member, match_cycle: :group).first
    return existing if existing&.topic && existing.response_slots.any?

    member = Member.new(name: "Ava Chen", email: "ava@example.com", time_zone: "Asia/Singapore")
    cycle = sample_cycle
    starts = MatchCycle.default_meeting_week_start.to_time(:utc).change(hour: 13)
    response = MatchResponse.new(
      match_cycle: cycle,
      member: member,
      topic: Topic.new(name: "Leadership")
    )
    response.response_slots.build(starts_at: starts, ends_at: starts + 1.hour)
    response
  end
end
