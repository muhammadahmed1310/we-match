# frozen_string_literal: true

# Confirmation email after someone submits (or updates) their availability.
class ResponseConfirmation
  def self.deliver!(match_response)
    MailDelivery.deliver(
      mailer: MatchCycleMailer,
      action: :response_confirmation,
      args: [ match_response ],
      member: match_response.member,
      match_cycle: match_response.match_cycle
    )
  end
end
