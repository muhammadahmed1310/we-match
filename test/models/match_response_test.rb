# frozen_string_literal: true

require "test_helper"

class MatchResponseTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Response Group")
    @other_group = create_group(name: "Other Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    @window = window_at(@cycle, hour: 13)
  end

  test "builds a one-hour slot from a local selection" do
    response = create_response(cycle: @cycle, member: @member, topic: @topic, windows: [ @window ], time_zone: "Asia/Karachi")

    slot = response.response_slots.sole
    assert_equal @window, slot.starts_at.utc
    assert_equal @window + 1.hour, slot.ends_at.utc
  end

  test "stores the same instant for the same hour in different zones" do
    other = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])

    karachi = create_response(cycle: @cycle, member: @member, topic: @topic, windows: [ @window ], time_zone: "Asia/Karachi")
    london = create_response(cycle: @cycle, member: other, topic: @topic, windows: [ @window ], time_zone: "Europe/London")

    assert_equal karachi.response_slots.first.starts_at.utc, london.response_slots.first.starts_at.utc
  end

  test "saves the time zone back onto the person" do
    create_response(cycle: @cycle, member: @member, topic: @topic, windows: [ @window ], time_zone: "Africa/Lagos")

    assert_equal "Africa/Lagos", @member.reload.time_zone
  end

  test "requires at least one window" do
    response = MatchResponse.new(match_cycle: @cycle, member: @member, topic: @topic, slot_selections: [])

    refute response.valid?
    assert_includes response.errors.full_messages, "Choose at least one 1-hour window"
  end

  test "allows at most two windows" do
    selections = [ 0, 1, 2 ].map { |offset| selection_for(@cycle, @window + offset.hours) }
    response = MatchResponse.new(match_cycle: @cycle, member: @member, topic: @topic, slot_selections: selections)

    refute response.valid?
    assert_includes response.errors.full_messages, "Choose at most 2 1-hour windows"
  end

  test "rejects a window outside the windows the cycle offers" do
    response = MatchResponse.new(
      match_cycle: @cycle,
      member: @member,
      topic: @topic,
      slot_selections: [ "2020-01-01 13" ]
    )

    refute response.valid?
    assert_includes response.errors.full_messages, "One of the chosen windows is not offered for this cycle"
  end

  test "rejects a topic that belongs to another group" do
    other_topic = create_topic(name: "Group-only topic", group: @other_group)
    response = MatchResponse.new(
      match_cycle: @cycle,
      member: @member,
      topic: other_topic,
      slot_selections: [ selection_for(@cycle, @window) ]
    )

    refute response.valid?
    assert_includes response.errors.full_messages, "Topic is not available to this group"
  end

  test "rejects someone who is not in the cycle's group" do
    outsider = create_member(name: "Outsider", email: "outsider@example.com", groups: [ @other_group ])
    response = MatchResponse.new(
      match_cycle: @cycle,
      member: outsider,
      topic: @topic,
      slot_selections: [ selection_for(@cycle, @window) ]
    )

    refute response.valid?
    assert_includes response.errors.full_messages, "This person must belong to the match cycle's group"
  end

  test "rejects an option from a different topic" do
    other_topic = create_topic(name: "Mentorship", options: [ "Finding a mentor" ])
    response = MatchResponse.new(
      match_cycle: @cycle,
      member: @member,
      topic: @topic,
      topic_option: other_topic.topic_options.first,
      slot_selections: [ selection_for(@cycle, @window) ]
    )

    refute response.valid?
    assert_includes response.errors.full_messages, "Topic option does not belong to the selected topic"
  end

  test "replaces slots when the selection changes" do
    response = create_response(cycle: @cycle, member: @member, topic: @topic, windows: [ @window ])

    response.update!(slot_selections: [ selection_for(@cycle, @window + 3.hours) ])

    assert_equal [ @window + 3.hours ], response.reload.response_slots.map { |slot| slot.starts_at.utc }
  end

  test "one response per person per cycle" do
    create_response(cycle: @cycle, member: @member, topic: @topic, windows: [ @window ])
    duplicate = MatchResponse.new(
      match_cycle: @cycle,
      member: @member,
      topic: @topic,
      slot_selections: [ selection_for(@cycle, @window) ]
    )

    refute duplicate.valid?
  end

  test "insight label prefers free text over the chosen option" do
    response = create_response(
      cycle: @cycle,
      member: @member,
      topic: @topic,
      windows: [ @window ],
      option: @topic.topic_options.first,
      option_other: "Something in my own words"
    )

    assert_equal "Something in my own words", response.insight_label
  end
end
