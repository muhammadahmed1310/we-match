# frozen_string_literal: true

require "test_helper"

class MatchMailerTest < ActionMailer::TestCase
  setup do
    @group = create_group(name: "Mailer Group")
    @topic = create_topic(name: "Leadership", options: [ "Difficult conversations", "Leading without authority" ])
    @member_a = create_member(name: "Alice", email: "alice@example.com", time_zone: "Asia/Karachi", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", time_zone: "Europe/London", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    @window = window_at(@cycle, hour: 9)

    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ @window ], option: @topic.topic_options.first)
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ @window ], option: @topic.topic_options.second)

    @match = MatchingService.new(@cycle).call.matches.sole
  end

  test "introduces both people" do
    mail = MatchMailer.introduction(@match)

    assert_equal [ "alice@example.com", "bob@example.com" ], mail.to
    assert_match "Alice", body(mail)
    assert_match "Bob", body(mail)
  end

  test "names the shared topic and the shared window" do
    mail = MatchMailer.introduction(@match)

    assert_match "Leadership", body(mail)
    assert_match @window.strftime("%H:%M"), body(mail)
  end

  test "shows the window in each person's own time zone" do
    mail = MatchMailer.introduction(@match)

    assert_match "PKT", body(mail)
    assert_match(/BST|GMT/, body(mail))
  end

  test "never reveals the topic option either person chose" do
    mail = MatchMailer.introduction(@match)

    assert_no_match "Difficult conversations", body(mail)
    assert_no_match "Leading without authority", body(mail)
  end

  test "sends from a WE address rather than the Rails default" do
    mail = MatchMailer.introduction(@match)

    assert_equal [ "no-reply@womenemerging.org" ], mail.from
  end

  private

  def body(mail)
    mail.all_parts.map(&:decoded).join("\n")
  end
end
