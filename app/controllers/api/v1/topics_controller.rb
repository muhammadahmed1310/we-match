# frozen_string_literal: true

module Api
  module V1
    class TopicsController < BaseController
      def index
        topics = Topic.includes(:group, :topic_options).ordered

        render json: topics.as_json(
          only: %i[id name description group_id active position],
          include: {
            topic_options: { only: %i[id label active position] }
          }
        )
      end
    end
  end
end
