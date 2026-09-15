# frozen_string_literal: true

# Preview: http://localhost:3000/rails/mailers/match_feedback_mailer/request_feedback
class MatchFeedbackMailerPreview < ActionMailer::Preview
  def request_feedback
    feedback = MatchFeedback.includes(:member, match: [ :topic, :member_one, :member_two, { match_cycle: :group } ]).first
    raise "Create a match feedback first (run a matched cycle and ensure feedbacks)." if feedback.nil?

    MatchFeedbackMailer.request_feedback(feedback)
  end
end
