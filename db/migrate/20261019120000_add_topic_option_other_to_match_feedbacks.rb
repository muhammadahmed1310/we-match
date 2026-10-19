# frozen_string_literal: true

class AddTopicOptionOtherToMatchFeedbacks < ActiveRecord::Migration[7.2]
  def change
    add_column :match_feedbacks, :topic_option_other, :string
  end
end
