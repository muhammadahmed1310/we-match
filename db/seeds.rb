# frozen_string_literal: true

puts "Seeding WE Match..."

# Seeding replaces everything below, so it must never run by accident against the
# pilot database. Real groups and people arrive by CSV import, not from here.
if Rails.env.production? && ENV["ALLOW_DESTRUCTIVE_SEED"] != "true"
  abort "Refusing to seed production: this deletes all groups, people, cycles, and responses. Set ALLOW_DESTRUCTIVE_SEED=true if that is really what you want."
end

MatchFeedback.destroy_all if defined?(MatchFeedback)
ResponseSlot.destroy_all
MatchResponse.destroy_all
Match.destroy_all
CycleInvitation.destroy_all
EmailDelivery.destroy_all
MatchCycle.destroy_all
GroupMembership.destroy_all
TopicOption.destroy_all
Topic.destroy_all
Member.destroy_all
Group.destroy_all

# ——— Admin access ———
# Real accounts are created with `bin/rails admin:create`. This one only exists so a
# fresh development database is usable immediately.
if Rails.env.development?
  admin = AdminUser.find_or_initialize_by(email: "cm@womenemerging.org")
  admin.name = "WE Community Manager"
  admin.password = "change-me-please"
  admin.save!
  puts "Development admin: #{admin.email} / change-me-please"
end

# ——— People ———

members_data = [
  { name: "Ava Chen", email: "ava.chen@example.com", time_zone: "Asia/Singapore" },
  { name: "Brianna Lopez", email: "brianna.lopez@example.com", time_zone: "America/New_York" },
  { name: "Claire Okonkwo", email: "claire.okonkwo@example.com", time_zone: "Africa/Lagos" },
  { name: "Diana Patel", email: "diana.patel@example.com", time_zone: "Asia/Kolkata" },
  { name: "Elena Rossi", email: "elena.rossi@example.com", time_zone: "Europe/Rome" },
  { name: "Fatima Hassan", email: "fatima.hassan@example.com", time_zone: "Asia/Karachi" },
  { name: "Grace Kim", email: "grace.kim@example.com", time_zone: "Asia/Seoul" },
  { name: "Hannah Wright", email: "hannah.wright@example.com", time_zone: "Europe/London" }
]

members = members_data.map { |attrs| Member.create!(attrs) }

we_fellows = Group.create!(
  name: "WE Fellows",
  description: "Women who completed a WE Expedition.",
  cycle_programme_starts_on: Date.current
)

explorers_circle = Group.create!(
  name: "Explorers Circle",
  description: "Explorers currently engaging with the WE Community.",
  cycle_programme_starts_on: Date.current
)

members[0..5].each { |member| GroupMembership.create!(member: member, group: we_fellows, cohort: "2026") }

[ members[2], members[4], members[5], members[6], members[7] ].each do |member|
  GroupMembership.create!(member: member, group: explorers_circle, cohort: "2026")
end

# ——— Topics and their option dropdowns ———

topics_data = [
  {
    name: "Leadership",
    description: "Leading people, teams, and yourself.",
    options: [ "Leading a team for the first time", "Difficult conversations", "Leading without authority" ]
  },
  {
    name: "Career transitions",
    description: "Changing direction, sector, or scale.",
    options: [ "Deciding whether to move", "Returning after a break", "Moving into a new sector" ]
  },
  {
    name: "Mentorship",
    description: "Being mentored, and mentoring others.",
    options: [ "Finding a mentor", "Being a better mentor" ]
  },
  {
    name: "Balance and wellbeing",
    description: "Sustaining yourself over the long run.",
    options: [ "Boundaries at work", "Recovering from burnout" ]
  }
]

topics = topics_data.each_with_index.map do |attrs, index|
  topic = Topic.create!(
    name: attrs[:name],
    description: attrs[:description],
    position: index
  )

  attrs[:options].each_with_index do |label, option_index|
    topic.topic_options.create!(label: label, position: option_index)
  end

  topic
end

leadership, career, mentorship, = topics

# ——— An open cycle with responses that will match ———

meeting_week = MatchCycle.default_meeting_week_start
slot_one = Time.utc(meeting_week.year, meeting_week.month, meeting_week.day, 13) # Monday 13:00 UTC
slot_two = slot_one.advance(days: 1) # Tuesday 13:00 UTC
slot_three = slot_one.advance(days: 2, hours: 3) # Wednesday 16:00 UTC

fellows_cycle = MatchCycle.create!(
  group: we_fellows,
  status: :open,
  opens_at: 2.days.ago.change(hour: 9),
  closes_at: 2.days.from_now.change(hour: 17),
  meeting_week_start: meeting_week
)

CycleInvitationService.new(fellows_cycle).ensure_all!

def record_response(cycle, member, topic, option_label, slot_times)
  response = cycle.match_responses.create!(
    member: member,
    topic: topic,
    topic_option: topic.topic_options.find_by(label: option_label),
    time_zone: member.time_zone,
    slot_selections: slot_times.map do |slot_time|
      MeetingWindows.new(cycle, time_zone: member.time_zone).selection_for(slot_time)
    end
  )

  cycle.cycle_invitations.find_by(member: member)&.mark_responded!
  response
end

# Ava and Brianna share leadership + Monday 13:00 UTC.
record_response(fellows_cycle, members[0], leadership, "Difficult conversations", [ slot_one, slot_two ])
record_response(fellows_cycle, members[1], leadership, "Leading a team for the first time", [ slot_one ])

# Claire and Diana share career transitions + Tuesday 13:00 UTC.
record_response(fellows_cycle, members[2], career, "Returning after a break", [ slot_two ])
record_response(fellows_cycle, members[3], career, "Deciding whether to move", [ slot_two, slot_three ])

# Elena picks a topic nobody else chose, so she stays unmatched.
record_response(fellows_cycle, members[4], mentorship, "Finding a mentor", [ slot_three ])

explorers_cycle = MatchCycle.create!(
  group: explorers_circle,
  status: :draft,
  opens_at: 1.week.from_now.change(hour: 9),
  closes_at: 10.days.from_now.change(hour: 17)
)

CycleInvitationService.new(explorers_cycle).ensure_all!

puts "Created #{Member.count} people, #{Group.count} groups, #{Topic.count} topics, #{MatchCycle.count} match cycles."
puts "Open cycle: #{fellows_cycle.group.name} (id=#{fellows_cycle.id}) with #{fellows_cycle.match_responses.count} responses."
puts "Draft cycle: #{explorers_cycle.group.name} (id=#{explorers_cycle.id})"
puts "Sample private link: #{fellows_cycle.cycle_invitations.first&.response_path}"
