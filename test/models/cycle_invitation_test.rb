# frozen_string_literal: true

require "test_helper"

class CycleInvitationTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Invitation Group")
    @member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
  end

  test "generates a token" do
    invitation = @cycle.cycle_invitations.create!(member: @member)

    assert invitation.token.present?
    assert_operator invitation.token.length, :>=, 20
  end

  test "one invitation per person per cycle" do
    @cycle.cycle_invitations.create!(member: @member)

    refute @cycle.cycle_invitations.new(member: @member).valid?
  end

  test "tokens are unique across cycles" do
    other_cycle = create_cycle(group: @group)
    first = @cycle.cycle_invitations.create!(member: @member)
    second = other_cycle.cycle_invitations.create!(member: @member)

    refute_equal first.token, second.token
  end

  test "records sends and responses" do
    invitation = @cycle.cycle_invitations.create!(member: @member)

    invitation.mark_sent!
    invitation.mark_sent!
    invitation.mark_responded!

    assert_equal 2, invitation.send_count
    assert invitation.responded?
  end

  test "the response url carries the token" do
    invitation = @cycle.cycle_invitations.create!(member: @member)

    assert_includes invitation.response_url, invitation.token
  end
end
