# frozen_string_literal: true

require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
  end

  test "creates a group" do
    assert_difference -> { Group.count }, 1 do
      post groups_path, params: { group: { name: "New Circle", description: "A new circle" } }
    end

    assert_redirected_to group_path(Group.last)
  end

  test "rejects a duplicate name" do
    create_group(name: "Fellows")

    post groups_path, params: { group: { name: "fellows" } }

    assert_response :unprocessable_entity
  end

  test "switches biweekly automation on and off" do
    group = create_group(name: "Fellows")

    patch toggle_auto_cycle_group_path(group)
    assert group.reload.auto_cycle?

    patch toggle_auto_cycle_group_path(group)
    refute group.reload.auto_cycle?
  end

  test "deleting a group takes its cycles with it" do
    group = create_group(name: "Fellows")
    create_cycle(group: group)

    assert_difference -> { MatchCycle.count }, -1 do
      delete group_path(group)
    end

    assert_redirected_to groups_path
  end

  test "the group page loads" do
    group = create_group(name: "Fellows")

    get group_path(group)

    assert_response :success
  end
end
