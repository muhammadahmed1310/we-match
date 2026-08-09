# frozen_string_literal: true

# Pairs people who chose the same topic and the same 1-hour window.
#
# Windows are compared as UTC instants, so two people in different time zones who
# picked the same hour are compatible. Pairs that already met in one of the group's
# recent cycles are held back to a second pass, so small cohorts running many
# rounds don't keep re-introducing the same two people — but a repeat is still
# better than leaving someone unmatched.
class MatchingService
  LOOKBACK_CYCLES = 6

  Result = Struct.new(:matches, :unmatched, :repeat_pairs, keyword_init: true)

  class AlreadyMatchedError < StandardError; end

  def initialize(match_cycle)
    @cycle = match_cycle
  end

  def call
    raise AlreadyMatchedError, "Matching has already been run for this cycle." if @cycle.matched?

    responses = @cycle.match_responses.unmatched.includes(:member, :topic, :response_slots).to_a
    @recent_pairs = recent_pair_keys
    @matched_ids = Set.new
    @created_matches = []
    @repeat_pairs = 0

    pair_responses(responses, avoid_repeats: true)
    pair_responses(responses, avoid_repeats: false)

    @cycle.update!(status: :matched, matched_at: Time.current)

    @created_matches.each do |match|
      MailDelivery.deliver(
        mailer: MatchMailer,
        action: :introduction,
        args: [ match ],
        match: match,
        match_cycle: @cycle
      )
    end

    Result.new(
      matches: @created_matches,
      unmatched: responses.reject { |response| @matched_ids.include?(response.id) },
      repeat_pairs: @repeat_pairs
    )
  end

  private

  def pair_responses(responses, avoid_repeats:)
    available = responses.reject { |response| @matched_ids.include?(response.id) }

    # Fewest options first, so the hardest people to place get matched.
    available.sort_by { |response| [ partners_for(response, responses, avoid_repeats).size, response.id ] }.each do |response|
      next if @matched_ids.include?(response.id)

      candidates = partners_for(response, responses, avoid_repeats)
      partner = candidates.min_by { |candidate| [ partners_for(candidate, responses, avoid_repeats).size, candidate.id ] }
      next if partner.nil?

      create_match(response, partner)
    end
  end

  def create_match(response_a, response_b)
    shared_slot = shared_slots(response_a, response_b).min

    match = @cycle.matches.create!(
      member_one: response_a.member,
      member_two: response_b.member,
      topic: response_a.topic,
      matched_slot_starts_at: shared_slot && Time.at(shared_slot).utc
    )

    [ response_a, response_b ].each { |response| response.update!(match: match) }
    @matched_ids.merge([ response_a.id, response_b.id ])
    @created_matches << match
    @repeat_pairs += 1 if @recent_pairs.include?(pair_key(response_a.member_id, response_b.member_id))
  end

  def partners_for(response_a, responses, avoid_repeats)
    responses.select do |response_b|
      next false if response_a.id == response_b.id
      next false if @matched_ids.include?(response_b.id)
      next false if response_a.member_id == response_b.member_id
      next false unless same_topic?(response_a, response_b)
      next false if shared_slots(response_a, response_b).empty?
      next false if avoid_repeats && @recent_pairs.include?(pair_key(response_a.member_id, response_b.member_id))

      true
    end
  end

  def same_topic?(response_a, response_b)
    response_a.topic_id.present? && response_a.topic_id == response_b.topic_id
  end

  # Compared as epoch seconds so instants match regardless of the zone each side
  # was loaded in.
  def shared_slots(response_a, response_b)
    slot_keys(response_a) & slot_keys(response_b)
  end

  def slot_keys(response)
    response.response_slots.map { |slot| slot.starts_at.utc.to_i }
  end

  def recent_pair_keys
    recent_cycle_ids = MatchCycle.where(group_id: @cycle.group_id)
                                .where.not(id: @cycle.id)
                                .recent
                                .limit(LOOKBACK_CYCLES)
                                .pluck(:id)
    return Set.new if recent_cycle_ids.empty?

    Match.where(match_cycle_id: recent_cycle_ids)
         .pluck(:member_one_id, :member_two_id)
         .map { |one, two| pair_key(one, two) }
         .to_set
  end

  def pair_key(member_one_id, member_two_id)
    [ member_one_id, member_two_id ].sort
  end
end
