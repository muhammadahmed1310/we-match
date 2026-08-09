ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module WeMatchTestHelpers
  ADMIN_PASSWORD = "test-password-1234"

  def create_admin(email: "cm@example.org", name: "WE CM")
    AdminUser.create!(name: name, email: email, password: ADMIN_PASSWORD)
  end

  def sign_in_admin(admin = nil)
    admin ||= create_admin
    post sign_in_path, params: { email: admin.email, password: ADMIN_PASSWORD }
    admin
  end

  def create_group(name: "WE Fellows", **attributes)
    Group.create!(name: name, **attributes)
  end

  def create_member(name:, email:, time_zone: "UTC", groups: [])
    member = Member.create!(name: name, email: email, time_zone: time_zone)
    Array(groups).each { |group| GroupMembership.create!(member: member, group: group) }
    member
  end

  def create_topic(name: "Leadership", options: [], group: nil)
    topic = Topic.create!(name: name, group: group)
    options.each_with_index { |label, index| topic.topic_options.create!(label: label, position: index) }
    topic
  end

  def create_cycle(group:, status: :open, **attributes)
    defaults = {
      opens_at: 1.day.ago,
      closes_at: 2.days.from_now,
      meeting_week_start: MatchCycle.default_meeting_week_start
    }

    MatchCycle.create!(group: group, status: status, **defaults.merge(attributes))
  end

  # A UTC instant inside the cycle's meeting week, on the hour.
  def window_at(cycle, day_offset: 0, hour: 13)
    day = (cycle.meeting_week_start || MatchCycle.default_meeting_week_start) + day_offset
    Time.utc(day.year, day.month, day.day, hour)
  end

  def selection_for(cycle, utc_time, time_zone: "UTC")
    MeetingWindows.new(cycle, time_zone: time_zone).selection_for(utc_time)
  end

  def create_response(cycle:, member:, topic:, windows:, time_zone: nil, option: nil, option_other: nil)
    zone = time_zone || member.time_zone

    MatchResponse.create!(
      match_cycle: cycle,
      member: member,
      topic: topic,
      topic_option: option,
      topic_option_other: option_other,
      time_zone: zone,
      slot_selections: Array(windows).map { |utc_time| selection_for(cycle, utc_time, time_zone: zone) }
    )
  end
end

module ActiveSupport
  class TestCase
    # The suite runs in a few seconds, and forked workers hang on macOS here before
    # they even create their databases. Opt in with PARALLEL_WORKERS if that changes.
    parallelize(workers: Integer(ENV.fetch("PARALLEL_WORKERS", 1)))

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include WeMatchTestHelpers
  end
end
