# frozen_string_literal: true

require "test_helper"

class EmailPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = create_member(name: "Alice", email: "alice@example.com")
    @token = @member.email_preferences_token
  end

  test "shows preferences for a valid token" do
    get email_preferences_path(token: @token)

    assert_response :success
    assert_match "Email preferences", response.body
    assert_match "Unsubscribe from invitations and reminders", response.body
  end

  test "rejects an invalid token" do
    get email_preferences_path(token: "not-a-real-token")

    assert_response :not_found
    assert_match "isn’t valid", response.body
  end

  test "unsubscribe opts out of cycle emails" do
    post unsubscribe_email_preferences_path(token: @token)

    assert_redirected_to email_preferences_path(token: @token)
    assert @member.reload.opted_out_of_cycle_emails?
    follow_redirect!
    assert_match "Resubscribe", response.body
  end

  test "resubscribe opts back in" do
    @member.opt_out_of_cycle_emails!

    post resubscribe_email_preferences_path(token: @token)

    assert_redirected_to email_preferences_path(token: @token)
    assert @member.reload.receives_cycle_emails?
  end
end
