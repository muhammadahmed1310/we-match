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

  test "invitation dates use the full month name and year" do
    mail = MatchCycleMailer.invitation(@invitation)
    body = decoded_parts(mail)
    week_start = @cycle.meeting_week_range.first
    closes = @cycle.closes_at

    assert_match week_start.strftime("%B %-d, %Y"), body
    assert_match closes.strftime("%A, %B %-d, %Y, %H:%M UTC"), body
    assert_no_match(/\bSep\b/, body)
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

  test "the confirmation lists the topic and windows" do
    topic = create_topic(name: "Leadership")
    window = window_at(@cycle, hour: 13)
    response = create_response(cycle: @cycle, member: @member, topic: topic, windows: [ window ], time_zone: "UTC")

    mail = MatchCycleMailer.response_confirmation(response)
    body = decoded_parts(mail)

    assert_equal [ "alice@example.com" ], mail.to
    assert_match "recorded your availability", mail.subject
    assert_match "Leadership", body
    assert_match "Monday", body
    assert_match @invitation.token, body
  end

  test "html emails carry the WE logo and Montserrat" do
    mail = MatchCycleMailer.invitation(@invitation)
    html = mail.html_part.decoded

    assert mail.attachments["we-logo.png"].present?
    assert_match "Montserrat", html
    assert_match "WE Match", html
    assert_match "Women Emerging", html
  end

  private

  # Quoted-printable wraps long lines, so URLs only survive intact once decoded.
  # Inline logo attachments are binary and must be skipped.
  def decoded_parts(mail)
    parts = mail.multipart? ? mail.all_parts : [ mail ]
    parts.select { |part| part.text? || part.mime_type.to_s.start_with?("text/") }
         .map(&:decoded)
         .join("\n")
  end
end
