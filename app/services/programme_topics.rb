# frozen_string_literal: true

# Canonical WE Match programme topics. Replace existing topics carefully —
# ones still referenced by responses are deactivated instead of destroyed.
class ProgrammeTopics
  DEFINITIONS = [
    {
      name: "How do I jettison some elements of my leading?",
      options: [ "Good girl", "Imposter syndrome", "Saying yes to everything", "Other" ]
    },
    {
      name: "What big issues are we facing today when we lead?",
      options: [ "Climate change", "Challenges of AI", "Misogyny", "Other" ]
    },
    {
      name: "Can we brainstorm solutions to a leadership dilemma I’m facing now?",
      options: []
    }
  ].freeze

  Result = Struct.new(:created, :updated, :deactivated, :kept_inactive, keyword_init: true)

  def self.install!
    new.install!
  end

  def install!
    created = 0
    updated = 0
    deactivated = 0
    kept_inactive = 0

    ActiveRecord::Base.transaction do
      desired_names = DEFINITIONS.map { |definition| definition[:name] }

      Topic.where.not(name: desired_names).find_each do |topic|
        if topic.match_responses.exists? || topic.topic_options.joins(:match_feedbacks).exists?
          topic.update!(active: false)
          topic.topic_options.update_all(active: false)
          kept_inactive += 1
        elsif topic.destroy
          deactivated += 1
        else
          topic.update!(active: false)
          topic.topic_options.update_all(active: false)
          kept_inactive += 1
        end
      end

      DEFINITIONS.each_with_index do |definition, index|
        topic = Topic.find_or_initialize_by(name: definition[:name], group_id: nil)
        was_new = topic.new_record?
        topic.assign_attributes(active: true, position: index, group_id: nil)
        topic.save!
        was_new ? created += 1 : updated += 1

        sync_options!(topic, definition[:options])
      end
    end

    Result.new(created:, updated:, deactivated:, kept_inactive:)
  end

  private

  def sync_options!(topic, labels)
    labels.each_with_index do |label, index|
      option = topic.topic_options.find_or_initialize_by(label: label)
      option.assign_attributes(active: true, position: index)
      option.save!
    end

    topic.topic_options.where.not(label: labels).find_each do |option|
      if option.match_feedbacks.exists? || option.match_responses.exists?
        option.update!(active: false)
      else
        option.destroy!
      end
    end
  end
end
