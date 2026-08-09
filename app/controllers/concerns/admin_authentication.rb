# frozen_string_literal: true

# Every admin screen is private. Controllers that serve participants (the
# token-based response flow) opt out with `allow_participant_access`.
module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
    helper_method :current_admin, :signed_in_as_admin?
  end

  class_methods do
    def allow_participant_access(**options)
      skip_before_action :require_admin, **options
    end
  end

  private

  def current_admin
    return @current_admin if defined?(@current_admin)

    @current_admin = session[:admin_user_id] && AdminUser.find_by(id: session[:admin_user_id])
  end

  def signed_in_as_admin?
    current_admin.present?
  end

  def require_admin
    return if signed_in_as_admin?

    respond_to do |format|
      format.html do
        session[:return_to] = request.fullpath if request.get? || request.head?
        redirect_to sign_in_path, alert: "Please sign in to continue."
      end
      format.json { render_json_error("Authentication required.", status: :unauthorized) }
      format.any { head :unauthorized }
    end
  end

  def sign_in(admin_user)
    reset_session
    session[:admin_user_id] = admin_user.id
    admin_user.update_column(:last_signed_in_at, Time.current)
    @current_admin = admin_user
  end

  def sign_out
    reset_session
    @current_admin = nil
  end
end
