# frozen_string_literal: true

class MatchFeedbackMailer < ApplicationMailer
  def request_feedback(feedback)
    @feedback = feedback
    @member = feedback.member
    @partner = feedback.partner
    @topic = feedback.topic
    @group = feedback.match.match_cycle.group
    @feedback_url = feedback.feedback_url

    mail(
      to: @member.email,
      subject: "WE Match: How was your conversation with #{@partner.name}?"
    )
  end
end
