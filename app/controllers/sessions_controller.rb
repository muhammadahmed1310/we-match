# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_participant_access only: %i[new create]

  layout "minimal"

  def new
    redirect_to root_path and return if signed_in_as_admin?

    @email = ""
  end

  def create
    admin_user = AdminUser.authenticate(email: params[:email], password: params[:password])

    if admin_user
      destination = session[:return_to]
      sign_in(admin_user)
      redirect_to destination.presence || root_path, notice: "Signed in."
    else
      @email = params[:email].to_s
      flash.now[:alert] = "We could not sign you in with those details."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to sign_in_path, notice: "Signed out."
  end
end
