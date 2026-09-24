# frozen_string_literal: true

require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
  end

  test "creates a group with a programme start date" do
    assert_difference -> { Group.count }, 1 do
      post groups_path, params: {
        group: {
          name: "New Circle",
          description: "A new circle",
          cycle_programme_starts_on: Date.current
        }
      }
    end

    group = Group.last
    assert_redirected_to group_path(group)
    assert group.auto_cycle?
    assert_equal Date.current, group.cycle_programme_starts_on
    assert group.signup_token.present?
  end

  test "rejects a group without a programme start date" do
    post groups_path, params: { group: { name: "No Dates" } }

    assert_response :unprocessable_entity
  end

  test "rejects a duplicate name" do
    create_group(name: "Fellows")

    post groups_path, params: { group: { name: "fellows", cycle_programme_starts_on: Date.current } }

    assert_response :unprocessable_entity
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
    assert_match "Matching window", response.body
    assert_match "Sign-up link", response.body
    assert_match group_signup_path(token: group.signup_token), response.body
    assert_no_match "Switch automation", response.body
  end
end
