# frozen_string_literal: true

class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy]

  def index
    scope = Group.includes(:members).ordered

    respond_to do |format|
      format.html do
        @groups_page = paginate(scope)
        @groups = @groups_page.records
      end
      format.json { render json: scope.as_json(include: { members: { only: %i[id name email time_zone] } }) }
    end
  end

  def show
    @members_page = paginate(@group.members.order(:name), page_param: :members_page)
    @members = @members_page.records
    @match_cycles = @group.match_cycles.recent
    @topics = @group.available_topics

    respond_to do |format|
      format.html
      format.json do
        render json: @group.as_json(
          only: %i[id name description cycle_programme_starts_on cycle_programme_ends_on],
          include: {
            members: { only: %i[id name email time_zone] },
            match_cycles: { only: %i[id status opens_at closes_at matched_at] }
          }
        )
      end
    end
  end

  def new
    @group = Group.new(cycle_programme_starts_on: Date.current)
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

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, :cycle_programme_starts_on, :cycle_programme_ends_on)
  end
end
