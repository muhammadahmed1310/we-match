class ApplicationMailer < ActionMailer::Base
  default from: -> { MailDelivery.from_address }
  layout "mailer"
  before_action :attach_brand_logo

  private

  def attach_brand_logo
    path = Rails.root.join("app/assets/images/we-logo.png")
    return unless path.exist?

    attachments.inline["we-logo.png"] = {
      mime_type: "image/png",
      content: File.binread(path)
    }
  end
end
