# frozen_string_literal: true

module Api
  module V1
    class MembersController < BaseController
      def index
        members = Member.includes(:groups).order(:name)
        render json: members.as_json(include: { groups: { only: %i[id name] } })
      end
    end
  end
end
