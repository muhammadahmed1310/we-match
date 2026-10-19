# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :set_topic, only: %i[show]

  def index
    @topics = Topic.includes(:group, :topic_options).ordered
  end

  def show
    @topic_options = @topic.topic_options.ordered
    @response_count = @topic.match_responses.count
    @option_counts = MatchFeedback.where(topic_option_id: @topic.topic_options.select(:id)).group(:topic_option_id).count
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end
end
