# frozen_string_literal: true

require "test_helper"

class GroupSignupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = create_group(name: "Accelerator Explorers")
  end

  test "the public form opens without signing in" do
    get group_signup_path(token: @group.signup_token)

    assert_response :success
    assert_match "Join Accelerator Explorers", response.body
    assert_match "Full name", response.body
  end

  test "an unknown token is refused" do
    get group_signup_path(token: "not-a-real-token")

    assert_response :not_found
    assert_match "isn’t valid", response.body
  end

  test "signing up creates a user in that group" do
    assert_difference -> { Member.count }, 1 do
      assert_difference -> { GroupMembership.count }, 1 do
        post group_signup_path(token: @group.signup_token), params: {
          member: {
            name: "Ava Chen",
            email: "ava@example.com",
            time_zone: "Asia/Singapore"
          }
        }
      end
    end

    assert_redirected_to group_signup_confirmation_path(token: @group.signup_token)
    member = Member.find_by!(email: "ava@example.com")
    assert_equal "Ava Chen", member.name
    assert_equal "Asia/Singapore", member.time_zone
    assert_includes member.groups, @group
  end

  test "signing up again with the same email adds them only once" do
    create_member(name: "Ava Chen", email: "ava@example.com", time_zone: "UTC", groups: [ @group ])

    assert_no_difference -> { Member.count } do
      assert_no_difference -> { GroupMembership.count } do
        post group_signup_path(token: @group.signup_token), params: {
          member: {
            name: "Ava Chen",
            email: "ava@example.com",
            time_zone: "Asia/Singapore"
          }
        }
      end
    end

    assert_redirected_to group_signup_confirmation_path(token: @group.signup_token)
    assert_equal "Asia/Singapore", Member.find_by!(email: "ava@example.com").time_zone
  end

  test "an existing user in another group is added to this one" do
    other = create_group(name: "WE Fellows")
    member = create_member(name: "Ava Chen", email: "ava@example.com", groups: [ other ])

    assert_no_difference -> { Member.count } do
      assert_difference -> { GroupMembership.count }, 1 do
        post group_signup_path(token: @group.signup_token), params: {
          member: {
            name: "Ava Chen",
            email: "ava@example.com",
            time_zone: "UTC"
          }
        }
      end
    end

    assert_includes member.reload.groups, @group
    assert_includes member.groups, other
  end

  test "invalid details are rejected" do
    assert_no_difference -> { Member.count } do
      post group_signup_path(token: @group.signup_token), params: {
        member: { name: "", email: "not-an-email", time_zone: "UTC" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "thank-you page loads" do
    get group_signup_confirmation_path(token: @group.signup_token)

    assert_response :success
    assert_match "You're in", response.body
  end
end
