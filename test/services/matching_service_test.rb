# frozen_string_literal: true

require "test_helper"

class MatchingServiceTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Matching Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @other_topic = create_topic(name: "Mentorship")

    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @member_c = create_member(name: "Carol", email: "carol@example.com", groups: [ @group ])

    @cycle = create_cycle(group: @group)
    @window = window_at(@cycle, hour: 13)
  end

  test "matches two people who chose the same topic and the same window" do
    response_a = create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    response_b = create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_c, topic: @other_topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    assert_equal 1, result.unmatched.size
    assert response_a.reload.matched?
    assert response_b.reload.matched?
    assert @cycle.reload.matched?
    assert_equal @topic, result.matches.first.topic
    assert_equal @window, result.matches.first.matched_slot_starts_at.utc
  end

  test "matches across time zones when the chosen hour is the same instant" do
    karachi = create_member(name: "Fatima", email: "fatima@example.com", time_zone: "Asia/Karachi", groups: [ @group ])
    london = create_member(name: "Hannah", email: "hannah@example.com", time_zone: "Europe/London", groups: [ @group ])

    create_response(cycle: @cycle, member: karachi, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: london, topic: @topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    assert_equal @window, result.matches.first.matched_slot_starts_at.utc
  end

  test "does not match when the topic differs even if the window is shared" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @other_topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_empty result.matches
    assert_equal 2, result.unmatched.size
  end

  test "does not match when windows only sit next to each other" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window + 1.hour ])

    result = MatchingService.new(@cycle).call

    assert_empty result.matches
    assert_equal 2, result.unmatched.size
  end

  test "uses a second window to find a partner" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window, @window + 2.hours ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window + 2.hours ])

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    assert_equal @window + 2.hours, result.matches.first.matched_slot_starts_at.utc
  end

  test "leaves a lone response unmatched" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_empty result.matches
    assert_equal 1, result.unmatched.size
  end

  test "prefers a fresh partner over one from a recent cycle" do
    previous = create_cycle(group: @group, status: :matched, matched_at: 1.week.ago)
    previous.matches.create!(member_one: @member_a, member_two: @member_b)

    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_c, topic: @topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    pair = result.matches.first.member_ids.sort
    refute_equal [ @member_a.id, @member_b.id ].sort, pair
    assert_equal 0, result.repeat_pairs
  end

  test "falls back to a repeat pairing rather than leaving both unmatched" do
    previous = create_cycle(group: @group, status: :matched, matched_at: 1.week.ago)
    previous.matches.create!(member_one: @member_a, member_two: @member_b)

    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])

    result = MatchingService.new(@cycle).call

    assert_equal 1, result.matches.size
    assert_equal 1, result.repeat_pairs
  end

  test "queues one introduction email per match" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])

    assert_difference -> { EmailDelivery.where(mailer: "MatchMailer").count }, 1 do
      MatchingService.new(@cycle).call
    end
  end

  test "raises when the cycle is already matched" do
    @cycle.update!(status: :matched, matched_at: Time.current)

    assert_raises(MatchingService::AlreadyMatchedError) do
      MatchingService.new(@cycle).call
    end
  end
end
