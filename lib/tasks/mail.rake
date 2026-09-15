# frozen_string_literal: true

namespace :mail do
  desc "Send a one-off test email. Usage: bin/rails mail:test[you@example.com]"
  task :test, [ :to ] => :environment do |_task, args|
    to = args[:to].presence || ENV["MAIL_TEST_TO"]
    abort "Pass an address: bin/rails mail:test[you@example.com]" if to.blank?

    unless MailDelivery.enabled?
      abort "MailDelivery is disabled. Set EMAIL_DELIVERY_ENABLED=true (and SMTP_*) first."
    end

    unless WeMatchSmtp.configured?
      abort "SMTP is not configured. Set SMTP_ADDRESS, SMTP_USERNAME, and SMTP_PASSWORD."
    end

    class TestMailer < ApplicationMailer
      def smoke_test(address)
        mail(
          to: address,
          subject: "WE Match — test email",
          body: [
            "This is a smoke test from WE Match.",
            "APP_HOST=#{ENV.fetch('APP_HOST', '(unset)')}",
            "From=#{MailDelivery.from_address}",
            "Time=#{Time.current.utc.iso8601}"
          ].join("\n")
        )
      end
    end

    message = TestMailer.smoke_test(to)
    delivery = EmailDelivery.create!(
      mailer: "TestMailer",
      mailer_action: "smoke_test",
      subject: message.subject,
      recipients: to,
      status: :pending
    )

    begin
      message.deliver_now
      delivery.update!(status: :delivered, delivered_at: Time.current)
      puts "Delivered test email to #{to}."
      puts "Links in real mail will use host: #{Rails.application.config.action_mailer.default_url_options.inspect}"
    rescue StandardError => e
      delivery.update!(status: :failed, error_message: e.message.truncate(500))
      abort "Send failed: #{e.message}"
    end
  end
end
