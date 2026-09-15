# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails::MailersController.class_eval do
    layout "mailer_preview"
    helper ApplicationHelper
    helper MailerPreviewHelper

    # The shared header expects these helpers from AdminAuthentication, which
    # Rails::MailersController does not include by default.
    helper_method :current_admin, :signed_in_as_admin?

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      @current_admin = session[:admin_user_id] && AdminUser.find_by(id: session[:admin_user_id])
    end

    def signed_in_as_admin?
      current_admin.present?
    end
  end
end
