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
    assert_match "Excel file (.xlsx)", response.body
    assert_no_match "paste the rows", response.body
  end

  test "a preview writes nothing" do
    assert_no_difference -> { Member.count } do
      post import_path, params: { file: valid_xlsx }
    end

    assert_response :success
    assert_match "To add", response.body
  end

  test "confirming the import creates the people" do
    post import_path, params: { file: valid_xlsx }
    payload = css_select("input[name=import_payload]").first["value"]

    assert_difference -> { Member.count }, 1 do
      post import_path, params: { import_payload: payload, confirm: "1" }
    end

    assert_redirected_to members_path
  end

  test "an empty submission is rejected" do
    post import_path, params: {}

    assert_response :unprocessable_entity
    assert_match "Excel", flash[:alert] || response.body
  end

  test "a csv upload is rejected" do
    file = Rack::Test::UploadedFile.new(StringIO.new("name,email\nAmara,amara@example.org"), "text/csv", original_filename: "people.csv")

    post import_path, params: { file: file }

    assert_response :unprocessable_entity
    assert_match ".xlsx", flash[:alert] || response.body
  end

  test "a file with a bad row cannot be confirmed" do
    upload = xlsx_upload([ { "name" => "Amara", "email" => "not-an-email" } ])
    post import_path, params: { file: upload }
    payload = css_select("input[name=import_payload]").first["value"]

    assert_no_difference -> { Member.count } do
      post import_path, params: { import_payload: payload, confirm: "1" }
    end

    assert_response :unprocessable_entity
    refute Member.exists?(email: "not-an-email")
  end

  test "an uploaded xlsx file is read" do
    post import_path, params: { file: valid_xlsx }

    assert_response :success
    assert_match "amara@example.org", response.body
  end

  private

  def valid_xlsx
    xlsx_upload([
      {
        "name" => "Amara Okafor",
        "email" => "amara@example.org",
        "time_zone" => "Africa/Lagos",
        "groups" => "WE Fellows",
        "cohort" => "2026"
      }
    ])
  end
end
