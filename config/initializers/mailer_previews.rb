# frozen_string_literal: true

# Mailer previews are available in development always, and in production when
# SHOW_MAILER_PREVIEWS=true. They stay off the public footer; share
# https://match.womenemerging.org/rails/mailers privately. Access requires
# an admin session so the index is not open to the internet.
Rails.application.config.after_initialize do
  next unless Rails.application.config.action_mailer.show_previews

  Rails::MailersController.class_eval do
    layout "mailer_preview"
    helper ApplicationHelper
    helper MailerPreviewHelper

    before_action :require_admin_for_mailer_previews

    helper_method :current_admin, :signed_in_as_admin?

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      @current_admin = session[:admin_user_id] && AdminUser.find_by(id: session[:admin_user_id])
    end

    def signed_in_as_admin?
      current_admin.present?
    end

    def require_admin_for_mailer_previews
      return if signed_in_as_admin?

      session[:return_to] = request.fullpath if request.get? || request.head?
      redirect_to "/sign_in", alert: "Please sign in to continue."
    end
  end
end
