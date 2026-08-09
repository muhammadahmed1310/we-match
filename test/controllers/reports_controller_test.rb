# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Report Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    window = window_at(@cycle, hour: 13)
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ window ], option: @topic.topic_options.first)
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ window ])
  end

  test "the overview loads" do
    get reports_path

    assert_response :success
    assert_match "Average response rate", response.body
  end

  test "the overview can be filtered to one group" do
    get reports_path(group_id: @group.id)

    assert_response :success
    assert_match @group.name, response.body
  end

  test "the overview exports a CSV" do
    get reports_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "Response rate %", response.body
  end

  test "the cycle report loads" do
    get cycle_report_path(@cycle)

    assert_response :success
    assert_match "Alice", response.body
  end

  test "the cycle report exports a CSV of results" do
    get cycle_report_path(@cycle, format: :csv)

    assert_response :success
    assert_match "Difficult conversations", response.body
  end
end
