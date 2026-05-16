# frozen_string_literal: true

class TopicCompatibility
  ALIAS_GROUPS = [
    %w[leadership leading teams leading_teams],
    %w[career transitions career_transitions career change],
    %w[mentorship mentoring],
    %w[wellness work life balance work-life balance]
  ].freeze

  def self.normalize(topic)
    topic.to_s.strip.downcase.gsub(/\s+/, " ")
  end

  def self.compatible?(topic_a, topic_b)
    key_a = canonical_key(topic_a)
    key_b = canonical_key(topic_b)
    key_a.present? && key_a == key_b
  end

  def self.canonical_key(topic)
    normalized = normalize(topic)
    return normalized if normalized.blank?

    ALIAS_GROUPS.each do |group|
      return group.first if group.include?(normalized)
    end

    normalized
  end
end
