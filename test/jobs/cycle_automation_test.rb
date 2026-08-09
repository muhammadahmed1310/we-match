# frozen_string_literal: true

require "test_helper"

class CycleAutomationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @group = create_group(name: "Automated Group", auto_cycle: true)
    @manual_group = create_group(name: "Manual Group")
    @topic = create_topic(name: "Leadership")
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group, @manual_group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group, @manual_group ])
  end

  test "opens a cycle and sends the invitations for an automated group" do
    cycles = OpenBiweeklyCyclesJob.perform_now

    assert_equal 1, cycles.size
    cycle = cycles.first
    assert cycle.open?
    assert cycle.auto_created?
    assert_equal 2, cycle.cycle_invitations.count
    assert_equal Date.current, @group.reload.auto_cycle_last_opened_on
  end

  test "leaves groups without automation alone" do
    OpenBiweeklyCyclesJob.perform_now

    assert_equal 0, @manual_group.match_cycles.count
  end

  test "does not open a second cycle within the fortnight" do
    OpenBiweeklyCyclesJob.perform_now
    @group.match_cycles.each { |cycle| cycle.update!(status: :matched, matched_at: Time.current) }

    assert_empty OpenBiweeklyCyclesJob.perform_now
  end

  test "opens again once the fortnight has passed" do
    OpenBiweeklyCyclesJob.perform_now
    @group.match_cycles.each { |cycle| cycle.update!(status: :matched, matched_at: Time.current) }
    @group.update!(auto_cycle_last_opened_on: 14.days.ago.to_date)

    assert_equal 1, OpenBiweeklyCyclesJob.perform_now.size
  end

  test "skips a group with fewer than two people" do
    solo_group = create_group(name: "Solo Group", auto_cycle: true)
    create_member(name: "Solo", email: "solo@example.com", groups: [ solo_group ])

    OpenBiweeklyCyclesJob.perform_now

    assert_equal 0, solo_group.match_cycles.count
  end

  test "closes a cycle whose window has passed" do
    cycle = create_cycle(group: @group, status: :open, opens_at: 5.days.ago, closes_at: 1.hour.ago)

    CloseDueCyclesJob.perform_now

    assert cycle.reload.closed?
  end

  test "leaves a cycle that is still inside its window open" do
    cycle = create_cycle(group: @group, status: :open, closes_at: 2.days.from_now)

    CloseDueCyclesJob.perform_now

    assert cycle.reload.open?
  end

  test "runs matching for closed automated cycles" do
    cycle = create_cycle(group: @group, status: :closed, auto_created: true)
    window = window_at(cycle, hour: 13)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: cycle, member: @member_b, topic: @topic, windows: [ window ])

    RunDueMatchingJob.perform_now

    assert cycle.reload.matched?
    assert_equal 1, cycle.matches.count
  end

  test "does not touch a cycle a Community Manager created by hand" do
    cycle = create_cycle(group: @group, status: :closed, auto_created: false)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window_at(cycle) ])

    RunDueMatchingJob.perform_now

    assert cycle.reload.closed?
  end

  test "leaves an empty automated cycle closed rather than matching nothing" do
    cycle = create_cycle(group: @group, status: :closed, auto_created: true)

    RunDueMatchingJob.perform_now

    assert cycle.reload.closed?
  end

  test "reminds only the people who have not responded" do
    cycle = create_cycle(group: @group, status: :open, closes_at: 1.day.from_now)
    CycleInvitationService.new(cycle).ensure_all!
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window_at(cycle) ])
    cycle.cycle_invitations.find_by(member: @member_a).mark_responded!

    assert_difference -> { EmailDelivery.where(mailer_action: "reminder").count }, 1 do
      SendResponseRemindersJob.perform_now
    end
  end

  test "does not remind when the deadline is still far off" do
    cycle = create_cycle(group: @group, status: :open, closes_at: 10.days.from_now)
    CycleInvitationService.new(cycle).ensure_all!

    assert_no_difference -> { EmailDelivery.count } do
      SendResponseRemindersJob.perform_now
    end
  end
end
