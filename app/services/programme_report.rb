# frozen_string_literal: true

require "csv"

# Aggregate view across cycles: are people responding, are they getting matched, and
# what does the WE Community keep asking to talk about.
class ProgrammeReport
  SUMMARY_HEADERS = [
    "Cycle", "Group", "Status", "Opened", "Closed", "Invited", "Responded",
    "Response rate %", "Matches", "Unmatched responses"
  ].freeze

  def initialize(group: nil)
    @group = group
  end

  def cycles
    @cycles ||= scope.includes(:group).recent.to_a
  end

  def cycle_reports
    @cycle_reports ||= cycles.map { |cycle| [ cycle, CycleReport.new(cycle) ] }
  end

  def average_response_rate
    rates = cycle_reports.map { |_cycle, report| report.response_rate }.reject(&:zero?)
    return 0.0 if rates.empty?

    (rates.sum / rates.size).round(1)
  end

  def total_matches
    Match.where(match_cycle_id: cycles.map(&:id)).count
  end

  def total_responses
    MatchResponse.where(match_cycle_id: cycles.map(&:id)).count
  end

  def unmatched_responses
    MatchResponse.where(match_cycle_id: cycles.map(&:id)).unmatched.count
  end

  def topic_distribution
    MatchResponse.where(match_cycle_id: cycles.map(&:id))
                 .joins(:topic)
                 .group("topics.name")
                 .count
                 .sort_by { |name, count| [ -count, name ] }
  end

  def option_distribution
    MatchResponse.where(match_cycle_id: cycles.map(&:id))
                 .where.not(topic_option_id: nil)
                 .joins(topic_option: :topic)
                 .group("topics.name", "topic_options.label")
                 .count
                 .map { |(topic_name, label), count| [ "#{topic_name} — #{label}", count ] }
                 .sort_by { |label, count| [ -count, label ] }
  end

  # Pairs that met more than once. Small cohorts hit this quickly, which is why
  # matching holds repeats back to a second pass.
  def repeat_pairs
    Match.where(match_cycle_id: cycles.map(&:id))
         .pluck(:member_one_id, :member_two_id)
         .group_by { |one, two| [ one, two ].sort }
         .select { |_pair, occurrences| occurrences.size > 1 }
         .size
  end

  def to_csv
    CSV.generate do |csv|
      csv << SUMMARY_HEADERS

      cycle_reports.each do |cycle, report|
        csv << [
          cycle.id,
          cycle.group.name,
          cycle.status,
          cycle.opens_at&.utc&.strftime("%Y-%m-%d %H:%M"),
          cycle.closes_at&.utc&.strftime("%Y-%m-%d %H:%M"),
          report.invited,
          report.responded,
          report.response_rate,
          report.matches_count,
          report.unmatched_count
        ]
      end
    end
  end

  private

  def scope
    @group ? @group.match_cycles : MatchCycle.all
  end
end
