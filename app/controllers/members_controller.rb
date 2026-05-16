# frozen_string_literal: true

class MembersController < ApplicationController
  def index
    @members = Member.includes(:groups).order(:name)

    respond_to do |format|
      format.html
      format.json { render json: @members.as_json(include: { groups: { only: %i[id name] } }) }
    end
  end

  def show
    @member = Member.includes(:groups, :match_responses).find(params[:id])
    @match_responses = @member.match_responses.includes(:match_cycle).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json do
        render json: @member.as_json(
          include: {
            groups: { only: %i[id name] },
            match_responses: {
              only: %i[id topic availability_start availability_end match_id],
              include: { match_cycle: { only: %i[id status] } }
            }
          }
        )
      end
    end
  end
end
