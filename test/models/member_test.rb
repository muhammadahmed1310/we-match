# frozen_string_literal: true

require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "requires a recognised time zone" do
    member = Member.new(name: "Alice", email: "alice@example.com", time_zone: "Mars/Olympus")

    refute member.valid?
    assert_includes member.errors.full_messages, "Time zone is not a recognised time zone"
  end

  test "accepts an IANA identifier" do
    member = Member.new(name: "Alice", email: "alice@example.com", time_zone: "Asia/Karachi")

    assert member.valid?
  end

  test "normalises the email" do
    member = Member.create!(name: "Alice", email: "  Alice@Example.COM ")

    assert_equal "alice@example.com", member.email
  end

  test "defaults to UTC" do
    assert_equal "UTC", Member.create!(name: "Alice", email: "alice@example.com").time_zone
  end

  test "rejects a duplicate email regardless of case" do
    Member.create!(name: "Alice", email: "alice@example.com")
    duplicate = Member.new(name: "Alice Again", email: "ALICE@example.com")

    refute duplicate.valid?
  end
end
