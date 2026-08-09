# frozen_string_literal: true

require "test_helper"

class TopicTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Topic Group")
  end

  test "a topic with no group is offered to every group" do
    topic = create_topic(name: "Leadership")

    assert topic.global?
    assert_includes @group.available_topics, topic
  end

  test "a group topic is only offered to that group" do
    other_group = create_group(name: "Another Group")
    topic = create_topic(name: "Group only", group: @group)

    assert_includes @group.available_topics, topic
    refute_includes other_group.available_topics, topic
  end

  test "inactive topics are not offered" do
    topic = create_topic(name: "Retired")
    topic.update!(active: false)

    refute_includes @group.available_topics, topic
  end

  test "topic names are unique within a scope" do
    create_topic(name: "Leadership")

    refute Topic.new(name: "leadership").valid?
  end

  test "cannot delete a topic that responses point at" do
    topic = create_topic(name: "Leadership")
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    cycle = create_cycle(group: @group)
    create_response(cycle: cycle, member: member, topic: topic, windows: [ window_at(cycle) ])

    refute topic.destroy
    assert Topic.exists?(topic.id)
  end

  test "only active options are selectable" do
    topic = create_topic(name: "Leadership", options: [ "Kept", "Retired" ])
    topic.topic_options.find_by(label: "Retired").update!(active: false)

    assert_equal [ "Kept" ], topic.selectable_options.map(&:label)
  end
end
