# frozen_string_literal: true

# Public sign-up for a specific group. Identity of the group comes from the
# signup token in the URL — no admin session required.
class GroupSignupsController < ApplicationController
  allow_participant_access

  layout "minimal"

  before_action :set_group

  def new
    @member = Member.new(time_zone: detected_time_zone)
  end

  def create
    @member = Member.new(member_params)

    unless privacy_acknowledged?
      @member.errors.add(:base, "Please confirm you have read the WE Match privacy notice.")
      return render :new, status: :unprocessable_entity
    end

    result = GroupSignup.new(@group, member_params).call
    @member = result.member

    if result.success?
      redirect_to group_signup_confirmation_path(token: @group.signup_token)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_group
    @group = Group.find_by(signup_token: params[:token])
    return if @group.present?

    render :unknown_link, status: :not_found
  end

  def member_params
    params.require(:member).permit(:name, :email, :time_zone)
  end

  def privacy_acknowledged?
    ActiveModel::Type::Boolean.new.cast(params[:privacy_acknowledged])
  end

  def detected_time_zone
    zone = params[:tz].presence || "UTC"
    ActiveSupport::TimeZone[zone] ? zone : "UTC"
  end
end
