# frozen_string_literal: true

require "test_helper"

class ParticipantResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = create_group(name: "Participant Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @member = create_member(name: "Alice Adeyemi", email: "alice@example.com", groups: [ @group ])
    @other = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    @invitation = @cycle.cycle_invitations.find_by(member: @member)
    @window = window_at(@cycle, hour: 13)
  end

  test "the form opens from a private link without any sign in" do
    get participant_response_path(token: @invitation.token)

    assert_response :success
    assert_match "Alice", response.body
  end

  test "an unknown token is refused" do
    get participant_response_path(token: "not-a-real-token")

    assert_response :not_found
    assert_match "don't recognise this link", response.body
  end

  test "submitting a response records it against the link's owner" do
    patch participant_response_path(token: @invitation.token), params: {
      match_response: {
        topic_id: @topic.id,
        topic_option_id: @topic.topic_options.first.id,
        time_zone: "Asia/Karachi",
        slot_selections: [ selection_for(@cycle, @window, time_zone: "Asia/Karachi"), "" ]
      }
    }

    assert_redirected_to participant_response_confirmation_path(token: @invitation.token)

    match_response = @cycle.match_responses.sole
    assert_equal @member, match_response.member
    assert_equal @topic, match_response.topic
    assert_equal [ @window ], match_response.response_slots.map { |slot| slot.starts_at.utc }
    assert @invitation.reload.responded?
    assert_equal "Asia/Karachi", @member.reload.time_zone
  end

  test "a member_id in the params cannot redirect the response to someone else" do
    patch participant_response_path(token: @invitation.token), params: {
      match_response: {
        member_id: @other.id,
        topic_id: @topic.id,
        time_zone: "UTC",
        slot_selections: [ selection_for(@cycle, @window) ]
      }
    }

    assert_equal @member, @cycle.match_responses.sole.member
  end

  test "a second visit edits the same response" do
    submit_valid_response

    patch participant_response_path(token: @invitation.token), params: {
      match_response: {
        topic_id: @topic.id,
        time_zone: "UTC",
        slot_selections: [ selection_for(@cycle, @window + 2.hours) ]
      }
    }

    assert_equal 1, @cycle.match_responses.count
    assert_equal [ @window + 2.hours ], @cycle.match_responses.sole.response_slots.map { |slot| slot.starts_at.utc }
  end

  test "an invalid submission re-renders the form" do
    patch participant_response_path(token: @invitation.token), params: {
      match_response: { topic_id: @topic.id, time_zone: "UTC", slot_selections: [ "" ] }
    }

    assert_response :unprocessable_entity
    assert_match "Choose at least one 1-hour window", response.body
  end

  test "a draft cycle explains that the round has not opened" do
    @cycle.update!(status: :draft)

    get participant_response_path(token: @invitation.token)

    assert_response :success
    assert_match "hasn't opened yet", response.body
  end

  test "a closed cycle refuses new responses" do
    @cycle.update!(status: :open, opens_at: 5.days.ago, closes_at: 1.day.ago)

    patch participant_response_path(token: @invitation.token), params: {
      match_response: { topic_id: @topic.id, time_zone: "UTC", slot_selections: [ selection_for(@cycle, @window) ] }
    }

    assert_response :success
    assert_match "closed", response.body
    assert_equal 0, @cycle.match_responses.count
  end

  test "a matched cycle refuses changes" do
    submit_valid_response
    @cycle.update!(status: :matched, matched_at: Time.current)

    get participant_response_path(token: @invitation.token)

    assert_response :success
    assert_match "Matching has already run", response.body
  end

  test "the confirmation page shows what was submitted" do
    submit_valid_response

    get participant_response_confirmation_path(token: @invitation.token)

    assert_response :success
    assert_match "Leadership", response.body
  end

  test "the confirmation page sends people back to the form when nothing was submitted" do
    get participant_response_confirmation_path(token: @invitation.token)

    assert_redirected_to participant_response_path(token: @invitation.token)
  end

  test "the chosen option never appears on the confirmation page" do
    submit_valid_response

    get participant_response_confirmation_path(token: @invitation.token)

    assert_no_match "Difficult conversations", response.body
  end

  private

  def submit_valid_response
    patch participant_response_path(token: @invitation.token), params: {
      match_response: {
        topic_id: @topic.id,
        topic_option_id: @topic.topic_options.first.id,
        time_zone: "UTC",
        slot_selections: [ selection_for(@cycle, @window) ]
      }
    }
  end
end
