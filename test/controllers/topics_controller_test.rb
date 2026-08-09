# frozen_string_literal: true

require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Topic Group")
  end

  test "lists topics" do
    create_topic(name: "Leadership")

    get topics_path

    assert_response :success
    assert_match "Leadership", response.body
  end

  test "creates a topic" do
    assert_difference -> { Topic.count }, 1 do
      post topics_path, params: { topic: { name: "Negotiation", description: "Asking for what you need", position: 1, active: "1" } }
    end

    assert_redirected_to topic_path(Topic.last)
  end

  test "rejects a topic without a name" do
    post topics_path, params: { topic: { name: "" } }

    assert_response :unprocessable_entity
  end

  test "adds an option to a topic" do
    topic = create_topic(name: "Leadership")

    assert_difference -> { TopicOption.count }, 1 do
      post topic_topic_options_path(topic), params: { topic_option: { label: "Difficult conversations", position: 0, active: "1" } }
    end

    assert_redirected_to topic_path(topic)
  end

  test "keeps a topic that responses point at and suggests deactivating it" do
    topic = create_topic(name: "Leadership")
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    cycle = create_cycle(group: @group)
    create_response(cycle: cycle, member: member, topic: topic, windows: [ window_at(cycle) ])

    delete topic_path(topic)

    assert_redirected_to topic_path(topic)
    assert_match "Mark it inactive", flash[:alert]
    assert Topic.exists?(topic.id)
  end

  test "keeps an option someone has already chosen so the insight survives" do
    topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    option = topic.topic_options.sole
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    cycle = create_cycle(group: @group)
    create_response(cycle: cycle, member: member, topic: topic, option: option, windows: [ window_at(cycle) ])

    delete topic_topic_option_path(topic, option)

    assert_redirected_to topic_path(topic)
    assert_match "inactive", flash[:alert]
    assert TopicOption.exists?(option.id)
  end

  test "deletes an option nobody has chosen" do
    topic = create_topic(name: "Leadership", options: [ "Unused angle" ])
    option = topic.topic_options.sole

    delete topic_topic_option_path(topic, option)

    assert_redirected_to topic_path(topic)
    refute TopicOption.exists?(option.id)
  end

  test "deletes an unused topic" do
    topic = create_topic(name: "Unused")

    delete topic_path(topic)

    assert_redirected_to topics_path
    refute Topic.exists?(topic.id)
  end
end
