# frozen_string_literal: true

require "csv"

# Everything a Community Manager needs to judge one round: who was invited, who
# answered, who got matched, and what the group wanted to talk about.
class CycleReport
  RESULT_HEADERS = [
    "Name", "Email", "Time zone", "Responded", "Topic", "Focus (private insight)",
    "Windows (UTC)", "Matched with", "Agreed window (UTC)"
  ].freeze

  def initialize(match_cycle)
    @cycle = match_cycle
  end

  def invited
    invitations.size
  end

  def responded
    responses.size
  end

  def response_rate
    return 0.0 if invited.zero?

    (responded.to_f / invited * 100).round(1)
  end

  def matched_count
    responses.count(&:matched?)
  end

  def matches_count
    @matches_count ||= @cycle.matches.count
  end

  def unmatched_count
    responded - matched_count
  end

  def silent_count
    invited - responded
  end

  def topic_distribution
    responses.group_by { |response| response.topic&.name || "No topic" }
             .transform_values(&:size)
             .sort_by { |name, count| [ -count, name ] }
  end

  def option_distribution
    responses.group_by { |response| response.insight_label.presence || "No preference given" }
             .transform_values(&:size)
             .sort_by { |label, count| [ -count, label ] }
  end

  def slot_distribution
    responses.flat_map(&:response_slots)
             .group_by { |slot| slot.starts_at.utc }
             .transform_values(&:size)
             .sort_by { |starts_at, _count| starts_at }
  end

  def rows
    invited_member_ids = invitations.map(&:member_id)
    members = invitations.map(&:member)
    # Responses a CM entered for someone who was never invited still belong in the report.
    members += responses.reject { |response| invited_member_ids.include?(response.member_id) }.map(&:member)

    members.uniq.sort_by(&:name).map do |member|
      response = responses.detect { |candidate| candidate.member_id == member.id }

      {
        member: member,
        response: response,
        partner: partner_for(response),
        agreed_window: response&.match&.slot_label_utc
      }
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << RESULT_HEADERS

      rows.each do |row|
        member = row[:member]
        response = row[:response]

        csv << [
          member.name,
          member.email,
          member.time_zone,
          response ? "yes" : "no",
          response&.topic&.name,
          response&.insight_label,
          response ? response.response_slots.map(&:utc_label).join(" | ") : nil,
          row[:partner]&.name,
          row[:agreed_window]
        ]
      end
    end
  end

  private

  def invitations
    @invitations ||= @cycle.cycle_invitations.joins(:member).includes(:member).order("members.name").to_a
  end

  def responses
    @responses ||= @cycle.match_responses.includes(:member, :topic, :topic_option, :response_slots, match: %i[member_one member_two]).to_a
  end

  def partner_for(response)
    return nil if response.nil? || response.match.nil?

    match = response.match
    match.member_one_id == response.member_id ? match.member_two : match.member_one
  end
end
