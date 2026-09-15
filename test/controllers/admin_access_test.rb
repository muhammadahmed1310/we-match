# frozen_string_literal: true

require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "every admin screen redirects to sign in when signed out" do
    group = create_group(name: "Private Group")
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ group ])
    cycle = create_cycle(group: group)
    topic = create_topic(name: "Leadership")

    [
      root_path,
      groups_path,
      group_path(group),
      members_path,
      member_path(member),
      match_cycles_path,
      match_cycle_path(cycle),
      invitations_match_cycle_path(cycle),
      topics_path,
      topic_path(topic),
      reports_path,
      cycle_report_path(cycle),
      new_import_path
    ].each do |path|
      get path
      assert_redirected_to sign_in_path, "#{path} should be private"
    end
  end

  test "signing in reaches the dashboard" do
    sign_in_admin

    get root_path
    assert_response :success
  end

  test "the sign in page is reachable without a session" do
    get sign_in_path
    assert_response :success
  end

  test "bad credentials do not sign anyone in" do
    admin = create_admin

    post sign_in_path, params: { email: admin.email, password: "wrong-password" }
    assert_response :unprocessable_entity

    get root_path
    assert_redirected_to sign_in_path
  end

  test "sign in returns to the page that was asked for" do
    create_admin
    get groups_path
    assert_redirected_to sign_in_path

    post sign_in_path, params: { email: "cm@example.org", password: WeMatchTestHelpers::ADMIN_PASSWORD }
    assert_redirected_to groups_path
  end

  test "signing out ends the session" do
    sign_in_admin

    delete sign_out_path
    assert_redirected_to sign_in_path

    get root_path
    assert_redirected_to sign_in_path
  end

  test "the health check stays public" do
    get rails_health_check_path
    assert_response :success
  end

  test "an admin password must be long enough" do
    admin = AdminUser.new(name: "Short", email: "short@example.org", password: "tooshort")

    refute admin.valid?
  end
end
