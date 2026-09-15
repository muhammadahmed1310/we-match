# frozen_string_literal: true

require "test_helper"

class MatchFeedbackMailerTest < ActionMailer::TestCase
  setup do
    @group = create_group(name: "Mailer Feedback Group")
    @topic = create_topic(name: "Jettisoning elements", options: [ "Good girl syndrome" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    window = window_at(@cycle, hour: 13)
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ window ])
    match = MatchingService.new(@cycle).call.matches.sole
    @feedback = MatchFeedback.create!(match: match, member: @member_a)
  end

  test "asks one matched person for feedback" do
    mail = MatchFeedbackMailer.request_feedback(@feedback)

    assert_equal [ "alice@example.com" ], mail.to
    assert_match "Alice", body(mail)
    assert_match "Bob", body(mail)
    assert_match @feedback.feedback_url, body(mail)
    assert_match "Jettisoning elements", body(mail)
    assert_no_match "Good girl syndrome", body(mail)
  end

  private

  def body(mail)
    parts = mail.multipart? ? mail.all_parts : [ mail ]
    parts.select { |part| part.text? || part.mime_type.to_s.start_with?("text/") }
         .map(&:decoded)
         .join("\n")
  end
end
