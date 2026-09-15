# frozen_string_literal: true

class CreateMatchFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :match_feedbacks do |t|
      t.references :match, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :topic_option, foreign_key: true
      t.string :token, null: false
      t.boolean :did_meet
      t.integer :value_for_time
      t.datetime :sent_at
      t.datetime :submitted_at
      t.integer :send_count, null: false, default: 0

      t.timestamps
    end

    add_index :match_feedbacks, :token, unique: true
    add_index :match_feedbacks, %i[match_id member_id], unique: true
  end
end
