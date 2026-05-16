# frozen_string_literal: true

puts "Seeding WE Match..."

MatchResponse.destroy_all
Match.destroy_all
MatchCycle.destroy_all
GroupMembership.destroy_all
Member.destroy_all
Group.destroy_all

members_data = [
  { name: "Ava Chen", email: "ava.chen@example.com" },
  { name: "Brianna Lopez", email: "brianna.lopez@example.com" },
  { name: "Claire Okonkwo", email: "claire.okonkwo@example.com" },
  { name: "Diana Patel", email: "diana.patel@example.com" },
  { name: "Elena Rossi", email: "elena.rossi@example.com" },
  { name: "Fatima Hassan", email: "fatima.hassan@example.com" },
  { name: "Grace Kim", email: "grace.kim@example.com" },
  { name: "Hannah Wright", email: "hannah.wright@example.com" }
]

members = members_data.map { |attrs| Member.create!(attrs) }

expedition_alumni = Group.create!(
  name: "Expedition Alumni",
  description: "Women who completed leadership expeditions in the last five years."
)

fellows_circle = Group.create!(
  name: "Fellows Circle",
  description: "Current fellows building peer support networks."
)

# Expedition Alumni: 6 members
members[0..5].each { |member| GroupMembership.create!(member: member, group: expedition_alumni) }

# Fellows Circle: 5 members with overlap (Grace is in both)
[ members[2], members[4], members[5], members[6], members[7] ].each do |member|
  GroupMembership.create!(member: member, group: fellows_circle)
end

base_time = Time.zone.parse("2026-05-20 14:00:00 UTC")

expedition_cycle = MatchCycle.create!(
  group: expedition_alumni,
  status: :open,
  opens_at: 2.weeks.ago,
  closes_at: 1.week.from_now
)

# Two pairs should match on leadership + overlapping windows; Diana stays unmatched (unique topic)
MatchResponse.create!(
  match_cycle: expedition_cycle,
  member: members[0],
  topic: "Leadership",
  availability_start: base_time,
  availability_end: base_time + 2.hours
)

MatchResponse.create!(
  match_cycle: expedition_cycle,
  member: members[1],
  topic: "Leading Teams",
  availability_start: base_time + 30.minutes,
  availability_end: base_time + 2.hours
)

MatchResponse.create!(
  match_cycle: expedition_cycle,
  member: members[2],
  topic: "Career Transitions",
  availability_start: base_time + 1.day,
  availability_end: base_time + 1.day + 90.minutes
)

MatchResponse.create!(
  match_cycle: expedition_cycle,
  member: members[3],
  topic: "Career Transitions",
  availability_start: base_time + 1.day + 30.minutes,
  availability_end: base_time + 1.day + 2.hours
)

MatchResponse.create!(
  match_cycle: expedition_cycle,
  member: members[4],
  topic: "Mentorship",
  availability_start: base_time + 2.days,
  availability_end: base_time + 2.days + 1.hour
)

fellows_cycle = MatchCycle.create!(
  group: fellows_circle,
  status: :draft,
  opens_at: 1.week.from_now,
  closes_at: 3.weeks.from_now
)

puts "Created #{Member.count} members, #{Group.count} groups, #{MatchCycle.count} match cycles."
puts "Open cycle: #{expedition_cycle.group.name} (id=#{expedition_cycle.id}) with #{expedition_cycle.match_responses.count} responses."
puts "Draft cycle: #{fellows_cycle.group.name} (id=#{fellows_cycle.id})"
