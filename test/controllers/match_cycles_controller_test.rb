# frozen_string_literal: true

require "test_helper"

class MatchCyclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Cycle Group")
    @topic = create_topic(name: "Leadership")
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
  end

  test "creating a cycle issues a private link for everyone in the group" do
    assert_difference -> { CycleInvitation.count }, 2 do
      post match_cycles_path, params: {
        match_cycle: { group_id: @group.id }
      }
    end

    cycle = MatchCycle.last
    assert_redirected_to match_cycle_path(cycle)
    assert cycle.draft?
    assert cycle.opens_at.present?
    assert cycle.closes_at.present?
    assert cycle.meeting_week_start.present?
  end

  test "the new cycle form only asks for a group" do
    get new_match_cycle_path

    assert_response :success
    assert_match "Select a group", response.body
    assert_no_match "Opens at", response.body
    assert_no_match "Status", response.body
  end

  test "sending invitations opens the cycle and records one email each" do
    cycle = create_cycle(group: @group, status: :draft)

    assert_difference -> { EmailDelivery.where(mailer: "MatchCycleMailer").count }, 2 do
      post send_invitations_match_cycle_path(cycle)
    end

    assert cycle.reload.open?
    assert_equal 2, cycle.cycle_invitations.where.not(sent_at: nil).count
  end

  test "invitations are not resent by default" do
    cycle = create_cycle(group: @group, status: :draft)
    post send_invitations_match_cycle_path(cycle)

    assert_no_difference -> { EmailDelivery.count } do
      post send_invitations_match_cycle_path(cycle)
    end
  end

  test "a resend goes to everyone again" do
    cycle = create_cycle(group: @group, status: :draft)
    post send_invitations_match_cycle_path(cycle)

    assert_difference -> { EmailDelivery.count }, 2 do
      post send_invitations_match_cycle_path(cycle, resend: 1)
    end
  end

  test "closing a cycle stops responses" do
    cycle = create_cycle(group: @group)

    post close_match_cycle_path(cycle)

    assert cycle.reload.closed?
    refute cycle.accepting_responses?
  end

  test "matching is refused without responses" do
    cycle = create_cycle(group: @group)

    post run_matching_match_cycle_path(cycle)

    assert_redirected_to match_cycle_path(cycle)
    assert_match "No responses yet", flash[:alert]
  end

  test "matching is refused for a draft cycle" do
    cycle = create_cycle(group: @group, status: :draft)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window_at(cycle) ])

    post run_matching_match_cycle_path(cycle)

    assert_match "open or closed", flash[:alert]
  end

  test "matching pairs the responses and reports the result" do
    cycle = create_cycle(group: @group)
    window = window_at(cycle, hour: 13)
    create_response(cycle: cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: cycle, member: @member_b, topic: @topic, windows: [ window ])

    post run_matching_match_cycle_path(cycle)

    assert_redirected_to match_cycle_matches_path(cycle)
    assert_equal 1, cycle.reload.matches.count
  end

  test "the invitation links page exports a CSV of private links" do
    cycle = create_cycle(group: @group)

    get invitations_match_cycle_path(cycle, format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "Private link", response.body
    assert_match cycle.cycle_invitations.first.token, response.body
  end

  test "the cycle page loads" do
    cycle = create_cycle(group: @group)

    get match_cycle_path(cycle)

    assert_response :success
  end
end
