# frozen_string_literal: true

# Preview: /rails/mailers/match_feedback_mailer/request_feedback
class MatchFeedbackMailerPreview < ActionMailer::Preview
  def request_feedback
    MatchFeedbackMailer.request_feedback(preview_feedback)
  end

  private

  def preview_feedback
    existing = MatchFeedback.includes(:member, match: [ :topic, :member_one, :member_two, { match_cycle: :group } ]).first
    return existing if existing&.member && existing.partner && existing.token.present?

    sample_feedback
  end

  def sample_feedback
    member_one = Member.new(name: "Ava Chen", email: "ava@example.com", time_zone: "Asia/Singapore")
    member_two = Member.new(name: "Brianna Lopez", email: "brianna@example.com", time_zone: "America/New_York")
    match = Match.new(
      match_cycle: MatchCycle.new(group: Group.new(name: "WE Fellows")),
      member_one: member_one,
      member_two: member_two,
      topic: Topic.new(name: "Leadership"),
      matched_slot_starts_at: MatchCycle.default_meeting_week_start.to_time(:utc).change(hour: 13)
    )

    MatchFeedback.new(match: match, member: member_one, token: "preview-feedback-token")
  end
end
