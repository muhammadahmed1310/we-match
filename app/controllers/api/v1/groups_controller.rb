# frozen_string_literal: true

module Api
  module V1
    class GroupsController < BaseController
      def index
        groups = Group.includes(:members).order(:name)
        render json: groups.as_json(include: { members: { only: %i[id name email] } })
      end
    end
  end
end
