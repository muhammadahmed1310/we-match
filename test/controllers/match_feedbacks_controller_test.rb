# frozen_string_literal: true

require "test_helper"

class MatchFeedbackFlowTest < ActionDispatch::IntegrationTest
  setup do
    @group = create_group(name: "Feedback Group")
    @topic = create_topic(name: "Jettisoning elements", options: [ "Good girl syndrome", "Perfectionism" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @cycle = create_cycle(
      group: @group,
      status: :open,
      meeting_week_start: 21.days.ago.to_date.beginning_of_week(:monday)
    )
    window = window_at(@cycle, hour: 13)
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ window ])
    @match = MatchingService.new(@cycle).call.matches.sole
    MatchFeedbackService.new(@cycle).ensure_all!
    @feedback = MatchFeedback.find_by!(match: @match, member: @member_a)
  end

  test "the feedback form opens from a private link" do
    get match_feedback_path(token: @feedback.token)

    assert_response :success
    assert_match "Did you actually meet", response.body
    assert_match "Jettisoning elements", response.body
    assert_match "Good girl syndrome", response.body
  end

  test "submitting feedback records meet value and subtopic" do
    patch match_feedback_path(token: @feedback.token), params: {
      match_feedback: {
        did_meet: true,
        value_for_time: 5,
        topic_option_id: @topic.topic_options.first.id
      }
    }

    assert_redirected_to match_feedback_confirmation_path(token: @feedback.token)
    @feedback.reload
    assert @feedback.submitted?
    assert @feedback.did_meet?
    assert_equal 5, @feedback.value_for_time
    assert_equal "Good girl syndrome", @feedback.insight_label
  end

  test "not meeting clears value and subtopic requirements" do
    patch match_feedback_path(token: @feedback.token), params: {
      match_feedback: {
        did_meet: false,
        value_for_time: 5,
        topic_option_id: @topic.topic_options.first.id
      }
    }

    assert_redirected_to match_feedback_confirmation_path(token: @feedback.token)
    @feedback.reload
    refute @feedback.did_meet?
    assert_nil @feedback.value_for_time
    assert_nil @feedback.topic_option_id
  end

  test "an unknown feedback token is refused" do
    get match_feedback_path(token: "made-up-token")

    assert_response :not_found
  end
end

class SendMatchFeedbackRequestsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @group = create_group(name: "Due Feedback Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
  end

  test "sends feedback requests one week after the match is paired" do
    cycle = create_cycle(
      group: @group,
      status: :open,
      meeting_week_start: 14.days.ago.to_date.beginning_of_week(:monday)
    )
    window = window_at(cycle, hour: 13)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: cycle, member: @member_b, topic: @topic, windows: [ window ])
    MatchingService.new(cycle).call
    cycle.update!(matched_at: 7.days.ago)

    assert_difference -> { MatchFeedback.where.not(sent_at: nil).count }, 2 do
      SendMatchFeedbackRequestsJob.perform_now
    end
  end

  test "does not send before one week after pairing" do
    cycle = create_cycle(
      group: @group,
      status: :open,
      meeting_week_start: 7.days.ago.to_date.beginning_of_week(:monday)
    )
    window = window_at(cycle, hour: 13)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: cycle, member: @member_b, topic: @topic, windows: [ window ])
    MatchingService.new(cycle).call
    cycle.update!(matched_at: 3.days.ago)

    assert_no_difference -> { MatchFeedback.where.not(sent_at: nil).count } do
      SendMatchFeedbackRequestsJob.perform_now
    end
  end
end
