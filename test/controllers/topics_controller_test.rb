# frozen_string_literal: true

require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Topic Group")
  end

  test "lists topics with edit and delete" do
    create_topic(name: "Leadership")

    get topics_path

    assert_response :success
    assert_match "Leadership", response.body
    assert_match "Edit", response.body
    assert_match "Delete", response.body
    assert_no_match "Hide from new forms", response.body
  end

  test "creates a topic with only a name" do
    assert_difference -> { Topic.count }, 1 do
      post topics_path, params: { topic: { name: "Negotiation" } }
    end

    topic = Topic.last
    assert_redirected_to topics_path
    assert topic.active?
    assert_nil topic.group_id
    assert topic.position.positive?
  end

  test "rejects a topic without a name" do
    post topics_path, params: { topic: { name: "" } }

    assert_response :unprocessable_entity
  end

  test "topic page manages subtopics" do
    topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])

    get topic_path(topic)

    assert_response :success
    assert_match "Subtopics", response.body
    assert_match "Difficult conversations", response.body
    assert_match "Add subtopic", response.body
  end

  test "keeps a topic that responses point at" do
    topic = create_topic(name: "Leadership")
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    cycle = create_cycle(group: @group)
    create_response(cycle: cycle, member: member, topic: topic, windows: [ window_at(cycle) ])

    delete topic_path(topic)

    assert_redirected_to topics_path
    assert_match "can't be deleted", flash[:alert]
    assert Topic.exists?(topic.id)
  end

  test "deletes an unused topic" do
    topic = create_topic(name: "Unused")

    delete topic_path(topic)

    assert_redirected_to topics_path
    refute Topic.exists?(topic.id)
  end
end
