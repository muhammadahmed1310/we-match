# frozen_string_literal: true

class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy toggle_auto_cycle]

  def index
    @groups = Group.includes(:members).ordered

    respond_to do |format|
      format.html
      format.json { render json: @groups.as_json(include: { members: { only: %i[id name email time_zone] } }) }
    end
  end

  def show
    @members = @group.members.order(:name)
    @match_cycles = @group.match_cycles.recent
    @topics = @group.available_topics

    respond_to do |format|
      format.html
      format.json do
        render json: @group.as_json(
          only: %i[id name description auto_cycle],
          include: {
            members: { only: %i[id name email time_zone] },
            match_cycles: { only: %i[id status opens_at closes_at matched_at] }
          }
        )
      end
    end
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to @group, notice: "Group created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: "Group updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @group.name
    @group.destroy
    redirect_to groups_path, notice: "#{name} deleted along with its cycles."
  end

  def toggle_auto_cycle
    @group.update!(auto_cycle: !@group.auto_cycle)

    notice = if @group.auto_cycle?
      "#{@group.name} will now open a cycle automatically every other Monday."
    else
      "Automatic cycles switched off for #{@group.name}."
    end

    redirect_to @group, notice: notice
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, :auto_cycle)
  end
end
