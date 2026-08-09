# frozen_string_literal: true

require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    create_group(name: "WE Fellows")
  end

  test "the upload form loads" do
    get new_import_path

    assert_response :success
  end

  test "a preview writes nothing" do
    assert_no_difference -> { Member.count } do
      post import_path, params: { csv_text: valid_csv }
    end

    assert_response :success
    assert_match "To add", response.body
  end

  test "confirming the import creates the people" do
    assert_difference -> { Member.count }, 1 do
      post import_path, params: { csv_text: valid_csv, confirm: "1" }
    end

    assert_redirected_to members_path
  end

  test "an empty submission is rejected" do
    post import_path, params: { csv_text: "" }

    assert_response :unprocessable_entity
  end

  test "a file with a bad row cannot be confirmed" do
    post import_path, params: { csv_text: "name,email\nAmara,not-an-email", confirm: "1" }

    assert_response :unprocessable_entity
    assert_equal 0, Member.count
  end

  test "an uploaded file is read" do
    file = Rack::Test::UploadedFile.new(StringIO.new(valid_csv), "text/csv", original_filename: "people.csv")

    post import_path, params: { file: file }

    assert_response :success
    assert_match "amara@example.org", response.body
  end

  private

  def valid_csv
    <<~CSV
      name,email,time_zone,groups,cohort
      Amara Okafor,amara@example.org,Africa/Lagos,WE Fellows,2026
    CSV
  end
end
