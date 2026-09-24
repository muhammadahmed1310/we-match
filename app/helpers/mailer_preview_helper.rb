# frozen_string_literal: true

module MailerPreviewHelper
  PREVIEW_DESCRIPTIONS = {
    "match_cycle_mailer" => "Invitation, reminder, and availability confirmation emails for a matching round.",
    "match_mailer" => "Introduction email sent to a matched pair after matching runs.",
    "match_feedback_mailer" => "Follow-up email one week after pairing, with a private feedback link."
  }.freeze

  PREVIEW_ICONS = {
    "match_cycle_mailer" => "✉️",
    "match_mailer" => "🤝",
    "match_feedback_mailer" => "📝"
  }.freeze

  def mailer_preview_description(preview_name)
    PREVIEW_DESCRIPTIONS[preview_name] || "Preview outgoing email."
  end

  def mailer_preview_icon(preview_name)
    PREVIEW_ICONS[preview_name] || "📧"
  end

  def mailer_preview_path(preview_name, email = nil)
    path = email ? "#{preview_name}/#{email}" : preview_name
    url_for(controller: "rails/mailers", action: "preview", path: path)
  end
end
