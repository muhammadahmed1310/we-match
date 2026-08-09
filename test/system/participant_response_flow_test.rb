# frozen_string_literal: true

require "application_system_test_case"

class ParticipantResponseFlowTest < ApplicationSystemTestCase
  setup do
    @group = create_group(name: "WE Fellows")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @member = create_member(name: "Alice Adeyemi", email: "alice@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    @invitation = @cycle.cycle_invitations.sole
  end

  test "someone responds from their private link" do
    visit participant_response_path(token: @invitation.token)

    assert_text "Hello Alice"

    select "Leadership", from: "match_response[topic_id]"
    assert_selector "select[name='match_response[topic_option_id]']:not([disabled])"
    select "Difficult conversations", from: "match_response[topic_option_id]"

    # Hour labels repeat across days, so pick by value rather than by text.
    _day_label, hours = MeetingWindows.new(@cycle).grouped_options.first
    find("#slot_selection_1 option[value='#{hours.first.last}']").select_option

    click_on "Submit my response"

    assert_text "Thank you, Alice"
    assert_text "Leadership"
    assert_no_text "Difficult conversations"
  end

  test "an unknown link is refused" do
    visit participant_response_path(token: "made-up-token")

    assert_text "We don't recognise this link"
  end
end
