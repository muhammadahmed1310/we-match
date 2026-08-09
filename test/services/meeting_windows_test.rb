# frozen_string_literal: true

require "test_helper"

class MeetingWindowsTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Windows Group")
    @cycle = create_cycle(group: @group, meeting_week_start: Date.new(2026, 8, 17))
  end

  test "offers the seven days of the meeting week" do
    windows = MeetingWindows.new(@cycle)

    assert_equal Date.new(2026, 8, 17), windows.days.first
    assert_equal Date.new(2026, 8, 23), windows.days.last
    assert_equal 7, windows.grouped_options.size
  end

  test "reads a local selection as a UTC instant" do
    windows = MeetingWindows.new(@cycle, time_zone: "Asia/Karachi")

    assert_equal Time.utc(2026, 8, 17, 9), windows.parse("2026-08-17 14")
  end

  test "the same hour in two zones is two different instants" do
    karachi = MeetingWindows.new(@cycle, time_zone: "Asia/Karachi").parse("2026-08-17 14")
    london = MeetingWindows.new(@cycle, time_zone: "Europe/London").parse("2026-08-17 14")

    refute_equal karachi, london
  end

  test "round-trips an instant back to a local selection" do
    windows = MeetingWindows.new(@cycle, time_zone: "Asia/Karachi")

    assert_equal "2026-08-17 14", windows.selection_for(Time.utc(2026, 8, 17, 9))
  end

  test "rejects a day outside the meeting week" do
    windows = MeetingWindows.new(@cycle)

    refute windows.valid_selection?("2026-09-01 13")
  end

  test "rejects an hour outside the offered range" do
    windows = MeetingWindows.new(@cycle)

    refute windows.valid_selection?("2026-08-17 3")
    assert windows.valid_selection?("2026-08-17 6")
  end

  test "rejects nonsense" do
    windows = MeetingWindows.new(@cycle)

    refute windows.valid_selection?("not a window")
    refute windows.valid_selection?(nil)
  end

  test "falls back to UTC for an unknown zone" do
    windows = MeetingWindows.new(@cycle, time_zone: "Mars/Olympus")

    assert_equal Time.utc(2026, 8, 17, 13), windows.parse("2026-08-17 13")
  end
end
