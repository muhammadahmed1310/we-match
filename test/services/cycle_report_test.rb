# frozen_string_literal: true

require "test_helper"

class CycleReportTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Report Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations", "Leading without authority" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @member_c = create_member(name: "Carol", email: "carol@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    @window = window_at(@cycle, hour: 13)
  end

  test "counts invitations, responses, and silence" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])

    report = CycleReport.new(@cycle)

    assert_equal 3, report.invited
    assert_equal 1, report.responded
    assert_equal 2, report.silent_count
    assert_in_delta 33.3, report.response_rate, 0.1
  end

  test "counts matches and unmatched responses" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_c, topic: @topic, windows: [ @window + 4.hours ])
    MatchingService.new(@cycle).call

    report = CycleReport.new(@cycle)

    assert_equal 1, report.matches_count
    assert_equal 1, report.unmatched_count
  end

  test "aggregates topics and the private option choices" do
    option = @topic.topic_options.first
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ], option: option)
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ], option: option)

    report = CycleReport.new(@cycle)

    assert_equal [ [ "Leadership", 2 ] ], report.topic_distribution
    assert_equal [ [ "Difficult conversations", 2 ] ], report.option_distribution
  end

  test "the CSV covers everyone invited, answered or not" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ], option: @topic.topic_options.first)

    csv = CSV.parse(CycleReport.new(@cycle).to_csv, headers: true)

    assert_equal 3, csv.size
    alice = csv.find { |row| row["Name"] == "Alice" }
    assert_equal "yes", alice["Responded"]
    assert_equal "Leadership", alice["Topic"]
    assert_equal "Difficult conversations", alice["Focus (private insight)"]
    assert_equal "no", csv.find { |row| row["Name"] == "Bob" }["Responded"]
  end

  test "the CSV names who each person was matched with" do
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ])
    MatchingService.new(@cycle).call

    csv = CSV.parse(CycleReport.new(@cycle).to_csv, headers: true)

    assert_equal "Bob", csv.find { |row| row["Name"] == "Alice" }["Matched with"]
    assert_equal "Alice", csv.find { |row| row["Name"] == "Bob" }["Matched with"]
  end
end
