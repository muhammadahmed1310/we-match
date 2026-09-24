# frozen_string_literal: true

require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @group = create_group(name: "Fellows")
    @other_group = create_group(name: "Explorers")
  end

  test "creates someone and puts them in the chosen groups with a cohort" do
    post members_path, params: {
      member: {
        name: "Amara Okafor",
        email: "amara@example.org",
        time_zone: "Africa/Lagos",
        memberships: {
          @group.id.to_s => { selected: "1", cohort: "2026" },
          @other_group.id.to_s => { selected: "0", cohort: "" }
        }
      }
    }

    member = Member.find_by(email: "amara@example.org")
    assert_redirected_to member_path(member)
    assert_equal [ "Fellows" ], member.groups.map(&:name)
    assert_equal "2026", member.group_memberships.sole.cohort
  end

  test "unchecking a group removes the membership" do
    member = create_member(name: "Amara", email: "amara@example.org", groups: [ @group ])

    patch member_path(member), params: {
      member: {
        name: "Amara",
        email: "amara@example.org",
        time_zone: "UTC",
        memberships: { @group.id.to_s => { selected: "0", cohort: "" } }
      }
    }

    assert_empty member.reload.groups
  end

  test "rejects an unrecognised time zone" do
    post members_path, params: { member: { name: "Amara", email: "amara@example.org", time_zone: "Mars/Olympus" } }

    assert_response :unprocessable_entity
  end

  test "removing someone takes their responses with them" do
    member = create_member(name: "Amara", email: "amara@example.org", groups: [ @group ])
    topic = create_topic(name: "Leadership")
    cycle = create_cycle(group: @group)
    create_response(cycle: cycle, member: member, topic: topic, windows: [ window_at(cycle) ])

    assert_difference -> { MatchResponse.count }, -1 do
      delete member_path(member)
    end

    assert_redirected_to members_path
  end

  test "removing someone who was emailed keeps the delivery log and clears the member link" do
    member = create_member(name: "Amara", email: "amara@example.org", groups: [ @group ])
    cycle = create_cycle(group: @group)
    delivery = EmailDelivery.create!(
      mailer: "MatchCycleMailer",
      mailer_action: "invitation",
      recipients: member.email,
      subject: "Invite",
      status: :delivered,
      member: member,
      match_cycle: cycle
    )

    assert_difference -> { Member.count }, -1 do
      delete member_path(member)
    end

    assert_redirected_to members_path
    assert_nil delivery.reload.member_id
    assert_equal "amara@example.org", delivery.recipients
  end

  test "the list loads" do
    create_member(name: "Amara", email: "amara@example.org", groups: [ @group ])

    get members_path

    assert_response :success
    assert_match "Amara", response.body
  end
end
