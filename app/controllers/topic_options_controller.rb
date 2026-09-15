# frozen_string_literal: true

class TopicOptionsController < ApplicationController
  before_action :set_topic
  before_action :set_topic_option, only: %i[edit update destroy toggle_active]

  def new
    @topic_option = @topic.topic_options.new
  end

  def create
    @topic_option = @topic.topic_options.new(topic_option_params)
    @topic_option.active = true
    @topic_option.position = next_position

    if @topic_option.save
      redirect_to @topic, notice: "Subtopic added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @topic_option.update(topic_option_params)
      redirect_to @topic, notice: "Subtopic updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    @topic_option.update!(active: !@topic_option.active?)
    status = @topic_option.active? ? "offered again" : "hidden from new forms"
    redirect_to @topic, notice: "#{@topic_option.label} is #{status}."
  end

  def destroy
    if @topic_option.destroy
      redirect_to @topic, notice: "Subtopic removed."
    else
      redirect_to @topic, alert: "#{@topic_option.label} has been chosen by someone, so it is kept for reporting. Hide it from new forms instead."
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def set_topic_option
    @topic_option = @topic.topic_options.find(params[:id])
  end

  def topic_option_params
    params.require(:topic_option).permit(:label)
  end

  def next_position
    (@topic.topic_options.maximum(:position) || 0) + 1
  end
end
