class ReplaceResponseTopicTextWithTopicReference < ActiveRecord::Migration[7.2]
  class MigrationTopic < ActiveRecord::Base
    self.table_name = "topics"
  end

  class MigrationResponse < ActiveRecord::Base
    self.table_name = "match_responses"
  end

  def up
    rename_column :match_responses, :topic, :legacy_topic
    change_column_null :match_responses, :legacy_topic, true

    add_reference :match_responses, :topic, foreign_key: true
    add_reference :match_responses, :topic_option, foreign_key: true
    add_column :match_responses, :topic_option_other, :string

    backfill_topics
  end

  def down
    remove_column :match_responses, :topic_option_other
    remove_reference :match_responses, :topic_option, foreign_key: true
    remove_reference :match_responses, :topic, foreign_key: true

    MigrationResponse.where(legacy_topic: nil).update_all(legacy_topic: "Unknown")
    change_column_null :match_responses, :legacy_topic, false
    rename_column :match_responses, :legacy_topic, :topic
  end

  private

  # Existing rows only carry free text, so fold them into Topic records using the
  # alias list that TopicCompatibility used before topics became data.
  def backfill_topics
    legacy_values = MigrationResponse.where.not(legacy_topic: nil).distinct.pluck(:legacy_topic)
    return if legacy_values.empty?

    legacy_values.each do |legacy_value|
      canonical = TopicCompatibility.canonical_key(legacy_value)
      next if canonical.blank?

      name = canonical.split.map(&:capitalize).join(" ")
      topic = MigrationTopic.find_or_create_by!(name: name, group_id: nil) do |record|
        record.description = "Migrated from free-text responses."
        record.active = true
        record.position = 0
        record.created_at = Time.current
        record.updated_at = Time.current
      end

      matching_values = legacy_values.select { |value| TopicCompatibility.canonical_key(value) == canonical }
      MigrationResponse.where(legacy_topic: matching_values).update_all(topic_id: topic.id)
    end
  end
end
