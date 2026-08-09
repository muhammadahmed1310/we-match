# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :set_member, only: %i[show edit update destroy]
  before_action :load_groups, only: %i[new create edit update]

  def index
    @members = Member.includes(:groups).order(:name)

    respond_to do |format|
      format.html
      format.json { render json: @members.as_json(only: %i[id name email time_zone], include: { groups: { only: %i[id name] } }) }
    end
  end

  def show
    @match_responses = @member.match_responses.includes(:match_cycle, :topic, :response_slots).order(created_at: :desc)
    @memberships = @member.group_memberships.includes(:group)

    respond_to do |format|
      format.html
      format.json do
        render json: @member.as_json(
          only: %i[id name email time_zone],
          include: { groups: { only: %i[id name] } }
        )
      end
    end
  end

  def new
    @member = Member.new(time_zone: "UTC")
  end

  def create
    @member = Member.new(member_params)

    if @member.save
      sync_memberships(@member)
      redirect_to @member, notice: "Added to the WE Community."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @member.update(member_params)
      sync_memberships(@member)
      redirect_to @member, notice: "Details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @member.name
    @member.destroy
    redirect_to members_path, notice: "#{name} removed, along with their responses and matches."
  end

  private

  def set_member
    @member = Member.includes(:groups).find(params[:id])
  end

  def load_groups
    @groups = Group.ordered
  end

  def member_params
    params.require(:member).permit(:name, :email, :time_zone)
  end

  # memberships => { "<group_id>" => { "selected" => "1", "cohort" => "2026" } }
  def sync_memberships(member)
    submitted = params.dig(:member, :memberships)
    return if submitted.blank?

    submitted.each do |group_id, attributes|
      membership = member.group_memberships.find_or_initialize_by(group_id: group_id.to_i)
      selected = ActiveModel::Type::Boolean.new.cast(attributes[:selected])

      if selected
        membership.cohort = attributes[:cohort].presence
        membership.save
      elsif membership.persisted?
        membership.destroy
      end
    end
  end
end
