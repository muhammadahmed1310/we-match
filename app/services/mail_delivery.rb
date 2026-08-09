# frozen_string_literal: true

# Single gate for outbound email.
#
# Production only sends once EMAIL_DELIVERY_ENABLED is set, which is what lets the
# pilot start before SPF/DKIM/DMARC exist on womenemerging.org: with the flag off
# nothing is sent, every intended email is still recorded, and CMs hand out the
# invitation links exported from the cycle page instead.
class MailDelivery
  DEFAULT_FROM = "WE Match <no-reply@womenemerging.org>"

  # EMAIL_DELIVERY_ENABLED decides when it is set. When it is not set, delivery is on
  # everywhere except production, where it must be turned on deliberately.
  def self.enabled?
    return ActiveModel::Type::Boolean.new.cast(ENV["EMAIL_DELIVERY_ENABLED"]).present? if ENV.key?("EMAIL_DELIVERY_ENABLED")

    !Rails.env.production?
  end

  def self.from_address
    ENV.fetch("MAIL_FROM", DEFAULT_FROM)
  end

  # Records what we intended to send, then queues the real delivery. The message is
  # materialised once here purely to capture the subject and recipients for the log.
  def self.deliver(mailer:, action:, args: [], member: nil, match_cycle: nil, match: nil)
    message = mailer.public_send(action, *args).message

    delivery = EmailDelivery.create!(
      mailer: mailer.name,
      mailer_action: action.to_s,
      subject: message.subject,
      recipients: Array(message.to).join(", "),
      status: enabled? ? :pending : :skipped,
      member: member,
      match_cycle: match_cycle,
      match: match
    )

    SendTrackedEmailJob.perform_later(delivery, mailer.name, action.to_s, *args) if enabled?

    delivery
  end
end
