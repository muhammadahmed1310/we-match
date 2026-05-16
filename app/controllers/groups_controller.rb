# frozen_string_literal: true

class GroupsController < ApplicationController
  def index
    @groups = Group.includes(:members).order(:name)

    respond_to do |format|
      format.html
      format.json { render json: @groups.as_json(include: { members: { only: %i[id name email] } }) }
    end
  end

  def show
    @group = Group.includes(:members, :match_cycles).find(params[:id])
    @match_cycles = @group.match_cycles.recent

    respond_to do |format|
      format.html
      format.json do
        render json: @group.as_json(
          include: {
            members: { only: %i[id name email] },
            match_cycles: { only: %i[id status opens_at closes_at matched_at] }
          }
        )
      end
    end
  end
end
