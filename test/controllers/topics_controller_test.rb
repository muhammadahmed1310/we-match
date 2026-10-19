# frozen_string_literal: true

require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Topic Group")
  end

  test "lists topics as view only" do
    create_topic(name: "Leadership")

    get topics_path

    assert_response :success
    assert_match "Leadership", response.body
    assert_match "View", response.body
    assert_no_match "New topic", response.body
    assert_no_match(/Edit/, response.body)
    assert_no_match "Delete", response.body
  end

  test "create and edit are blocked" do
    assert_raises(NameError) { new_topic_path }

    post "/topics", params: { topic: { name: "Negotiation" } }
    assert_response :not_found
  end

  test "topic page is view only" do
    topic = create_topic(name: "Leadership", options: [ "Difficult conversations", "Other" ])

    get topic_path(topic)

    assert_response :success
    assert_match "Subtopics", response.body
    assert_match "Difficult conversations", response.body
    assert_match "Other (what)", response.body
    assert_no_match "Add subtopic", response.body
    assert_no_match "Remove", response.body
  end

  test "open text topics explain the response field" do
    topic = create_topic(name: "Can we brainstorm solutions to a leadership dilemma I’m facing now?")

    get topic_path(topic)

    assert_response :success
    assert_match "open-text", response.body
  end
end
