# frozen_string_literal: true

class SendTrackedEmailJob < ApplicationJob
  queue_as :mailers

  retry_on Net::SMTPServerBusy, Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(email_delivery, mailer_name, action, *args)
    mailer_name.constantize.public_send(action, *args).deliver_now
    email_delivery.update!(status: :delivered, delivered_at: Time.current)
  rescue StandardError => e
    email_delivery.update!(status: :failed, error_message: e.message.truncate(500))
    raise
  end
end
