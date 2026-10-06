# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "the privacy notice is public" do
    get privacy_path

    assert_response :success
    assert_match "WE Match privacy notice", response.body
    assert_match "Your match does", response.body
    assert_match "anonymised totals", response.body
  end
end
