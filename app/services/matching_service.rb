# frozen_string_literal: true

class MatchingService
  Result = Struct.new(:matches, :unmatched, keyword_init: true)

  class AlreadyMatchedError < StandardError; end

  def initialize(match_cycle)
    @cycle = match_cycle
  end

  def call
    raise AlreadyMatchedError, "Matching has already been run for this cycle." if @cycle.matched?

    responses = @cycle.match_responses.unmatched.includes(:member).to_a
    matched_ids = Set.new
    created_matches = []

    sorted = responses.sort_by { |response| compatible_partners(response, responses, matched_ids).size }

    sorted.each do |response_a|
      next if matched_ids.include?(response_a.id)

      partner = compatible_partners(response_a, responses, matched_ids).first
      next unless partner

      match = @cycle.matches.create!(
        member_one: response_a.member,
        member_two: partner.member
      )

      [ response_a, partner ].each { |response| response.update!(match: match) }
      matched_ids.merge([ response_a.id, partner.id ])
      created_matches << match
      MatchMailer.introduction(match).deliver_now
    end

    @cycle.update!(status: :matched, matched_at: Time.current)

    Result.new(
      matches: created_matches,
      unmatched: responses.reject { |response| matched_ids.include?(response.id) }
    )
  end

  private

  def compatible_partners(response_a, responses, matched_ids)
    responses.select do |response_b|
      next false if response_a.id == response_b.id
      next false if matched_ids.include?(response_b.id)
      next false if response_a.member_id == response_b.member_id

      topics_compatible?(response_a, response_b) && availability_overlap?(response_a, response_b)
    end
  end

  def topics_compatible?(response_a, response_b)
    TopicCompatibility.compatible?(response_a.topic, response_b.topic)
  end

  def availability_overlap?(response_a, response_b)
    response_a.availability_start < response_b.availability_end &&
      response_b.availability_start < response_a.availability_end
  end
end
