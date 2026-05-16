# frozen_string_literal: true

require "test_helper"

class MatchingServiceTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Test Group", description: "Test")
    @member_a = Member.create!(name: "Alice", email: "alice@example.com")
    @member_b = Member.create!(name: "Bob", email: "bob@example.com")
    @member_c = Member.create!(name: "Carol", email: "carol@example.com")
    [ @member_a, @member_b, @member_c ].each do |member|
      GroupMembership.create!(member: member, group: @group)
    end

    @cycle = MatchCycle.create!(group: @group, status: :open, opens_at: Time.current)
  end

  test "matches members with overlapping availability and compatible topics" do
    base = Time.zone.parse("2026-06-01 10:00:00 UTC")

    response_a = create_response(@member_a, "Leadership", base, base + 1.hour)
    response_b = create_response(@member_b, "Leading Teams", base + 15.minutes, base + 90.minutes)
    create_response(@member_c, "Mentorship", base + 2.hours, base + 3.hours)

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    assert_equal 1, result.unmatched.size
    assert response_a.reload.matched?
    assert response_b.reload.matched?
    assert @cycle.reload.matched?
  end

  test "leaves unmatched when no compatible partner exists" do
    base = Time.zone.parse("2026-06-02 10:00:00 UTC")
    create_response(@member_a, "Leadership", base, base + 1.hour)
    create_response(@member_b, "Mentorship", base, base + 1.hour)

    result = MatchingService.new(@cycle).call

    assert_empty result.matches
    assert_equal 2, result.unmatched.size
  end

  test "does not match the same member twice in a cycle" do
    base = Time.zone.parse("2026-06-03 10:00:00 UTC")
    create_response(@member_a, "Leadership", base, base + 2.hours)

    result = MatchingService.new(@cycle).call

    assert_empty result.matches
    assert_equal 1, result.unmatched.size
  end

  test "raises when cycle is already matched" do
    @cycle.update!(status: :matched, matched_at: Time.current)

    assert_raises(MatchingService::AlreadyMatchedError) do
      MatchingService.new(@cycle).call
    end
  end

  private

  def create_response(member, topic, start_time, end_time)
    MatchResponse.create!(
      match_cycle: @cycle,
      member: member,
      topic: topic,
      availability_start: start_time,
      availability_end: end_time
    )
  end
end
