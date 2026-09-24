# frozen_string_literal: true

require "test_helper"

class GroupSignupTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "Accelerator Explorers")
  end

  test "creates a member and membership" do
    result = GroupSignup.new(@group, name: "Ava", email: "ava@example.com", time_zone: "UTC").call

    assert result.success?
    assert result.created
    assert result.added_to_group
    assert_equal @group, result.member.groups.first
  end

  test "rejects a blank name" do
    result = GroupSignup.new(@group, name: "", email: "ava@example.com", time_zone: "UTC").call

    refute result.success?
    assert_includes result.errors.join, "Name"
  end
end
