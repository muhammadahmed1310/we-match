# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails::MailersController.class_eval do
    layout "mailer_preview"
  end
end
