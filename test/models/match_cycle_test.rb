# frozen_string_literal: true

require "test_helper"

class MatchCycleTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Cycle Group")
    @member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
  end

  test "a draft cycle does not accept responses" do
    refute create_cycle(group: @group, status: :draft).accepting_responses?
  end

  test "an open cycle inside its dates accepts responses" do
    assert create_cycle(group: @group, status: :open).accepting_responses?
  end

  test "an open cycle past its closing date does not accept responses" do
    cycle = create_cycle(group: @group, status: :open, opens_at: 5.days.ago, closes_at: 1.day.ago)

    refute cycle.accepting_responses?
  end

  test "an open cycle before its opening date does not accept responses" do
    cycle = create_cycle(group: @group, status: :open, opens_at: 1.day.from_now, closes_at: 5.days.from_now)

    refute cycle.accepting_responses?
  end

  test "a matched cycle does not accept responses" do
    refute create_cycle(group: @group, status: :matched).accepting_responses?
  end

  test "closing must come after opening" do
    cycle = MatchCycle.new(group: @group, status: :draft, opens_at: 2.days.from_now, closes_at: 1.day.from_now)

    refute cycle.valid?
    assert_includes cycle.errors.full_messages, "Closes at must be after the opening date"
  end

  test "defaults the meeting week to the Monday after closing" do
    cycle = create_cycle(
      group: @group,
      opens_at: Time.utc(2026, 8, 10, 17),
      closes_at: Time.utc(2026, 8, 13, 17),
      meeting_week_start: nil
    )

    assert_equal Date.new(2026, 8, 17), cycle.meeting_week_start
    assert_equal 1, cycle.meeting_week_start.wday
  end

  test "response rate counts responses against invitations" do
    other = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    cycle = create_cycle(group: @group)
    CycleInvitationService.new(cycle).ensure_all!
    topic = create_topic(name: "Leadership")

    create_response(cycle: cycle, member: @member, topic: topic, windows: [ window_at(cycle) ])

    assert_equal 2, cycle.invited_count
    assert_equal 1, cycle.responded_count
    assert_in_delta 50.0, cycle.response_rate, 0.01
    assert other.persisted?
  end
end
