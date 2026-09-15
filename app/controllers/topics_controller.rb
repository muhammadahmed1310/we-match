# frozen_string_literal: true

class TopicsController < ApplicationController
  before_action :set_topic, only: %i[show edit update destroy]

  def index
    @topics = Topic.includes(:group, :topic_options).ordered
  end

  def show
    @topic_options = @topic.topic_options
    @response_count = @topic.match_responses.count
    @option_counts = MatchFeedback.where(topic_option_id: @topic.topic_options.select(:id)).group(:topic_option_id).count
  end

  def new
    @topic = Topic.new
  end

  def create
    @topic = Topic.new(topic_params)
    @topic.active = true
    @topic.group_id = nil
    @topic.position = next_position

    if @topic.save
      redirect_to topics_path, notice: "Topic created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @topic.update(topic_params)
      redirect_to topics_path, notice: "Topic updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @topic.destroy
      redirect_to topics_path, notice: "Topic deleted."
    else
      redirect_to topics_path, alert: "“#{@topic.name}” is used by existing responses, so it can't be deleted."
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name)
  end

  def next_position
    (Topic.maximum(:position) || 0) + 1
  end
end
