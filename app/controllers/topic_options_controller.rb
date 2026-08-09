# frozen_string_literal: true

class TopicOptionsController < ApplicationController
  before_action :set_topic
  before_action :set_topic_option, only: %i[edit update destroy]

  def new
    @topic_option = @topic.topic_options.new(active: true, position: next_position)
  end

  def create
    @topic_option = @topic.topic_options.new(topic_option_params)

    if @topic_option.save
      redirect_to @topic, notice: "Option added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @topic_option.update(topic_option_params)
      redirect_to @topic, notice: "Option updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @topic_option.destroy
      redirect_to @topic, notice: "Option removed."
    else
      redirect_to @topic, alert: "#{@topic_option.label} has been chosen by someone, so it is kept for reporting. Set it to inactive to stop offering it."
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
    params.require(:topic_option).permit(:label, :active, :position)
  end

  def next_position
    (@topic.topic_options.maximum(:position) || 0) + 1
  end
end
