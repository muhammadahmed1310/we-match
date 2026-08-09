# frozen_string_literal: true

require "application_system_test_case"

class AdminSignInTest < ApplicationSystemTestCase
  test "a Community Manager signs in and reaches the dashboard" do
    create_admin(email: "cm@womenemerging.org", name: "WE CM")

    visit root_path
    assert_text "Sign in"

    fill_in "Email", with: "cm@womenemerging.org"
    fill_in "Password", with: WeMatchTestHelpers::ADMIN_PASSWORD
    click_on "Sign in"

    assert_text "Dashboard"
    assert_text "WE CM"
  end

  test "the dashboard is not reachable without signing in" do
    visit groups_path

    assert_text "Please sign in to continue."
  end
end
