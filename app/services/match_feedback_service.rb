# frozen_string_literal: true

# Creates private feedback links for every matched person and emails them one week
# after the cycle was matched (pairs introduced).
class MatchFeedbackService
  Result = Struct.new(:created, :sent, keyword_init: true)

  def initialize(match_cycle)
    @cycle = match_cycle
  end

  def ensure_all!
    created = 0

    @cycle.matches.includes(:member_one, :member_two).find_each do |match|
      match.member_ids.each do |member_id|
        feedback = MatchFeedback.find_or_initialize_by(match: match, member_id: member_id)
        next if feedback.persisted?

        feedback.save!
        created += 1
      end
    end

    created
  end

  def deliver_requests!
    ensure_all!
    sent = 0

    MatchFeedback.unsubmitted
                 .where(match_id: @cycle.match_ids)
                 .includes(:member, match: %i[topic member_one member_two match_cycle])
                 .find_each do |feedback|
      next if feedback.sent?

      MailDelivery.deliver(
        mailer: MatchFeedbackMailer,
        action: :request_feedback,
        args: [ feedback ],
        member: feedback.member,
        match_cycle: @cycle,
        match: feedback.match
      )
      feedback.mark_sent!
      sent += 1
    end

    Result.new(created: 0, sent: sent)
  end
end
