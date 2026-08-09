# frozen_string_literal: true

require "test_helper"

class MatchCycleMailerTest < ActionMailer::TestCase
  setup do
    @group = create_group(name: "Invite Group")
    @member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    @invitation = @cycle.cycle_invitations.sole
  end

  test "the invitation carries the person's own private link" do
    mail = MatchCycleMailer.invitation(@invitation)

    assert_equal [ "alice@example.com" ], mail.to
    assert_match @invitation.token, decoded_parts(mail)
    assert_match "personal to you", decoded_parts(mail)
  end

  test "the invitation does not offer a way to respond as somebody else" do
    mail = MatchCycleMailer.invitation(@invitation)

    assert_no_match(/member_id=/, decoded_parts(mail))
  end

  test "the reminder links to the same private link" do
    mail = MatchCycleMailer.reminder(@invitation)

    assert_match @invitation.token, decoded_parts(mail)
    assert_match "reminder", mail.subject
  end

  private

  # Quoted-printable wraps long lines, so URLs only survive intact once decoded.
  def decoded_parts(mail)
    mail.all_parts.map(&:decoded).join("\n")
  end
end
