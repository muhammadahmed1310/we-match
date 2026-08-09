class ApplicationMailer < ActionMailer::Base
  default from: -> { MailDelivery.from_address }
  layout "mailer"
end
