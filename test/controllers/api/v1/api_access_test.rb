# frozen_string_literal: true

require "test_helper"

class Api::V1::ApiAccessTest < ActionDispatch::IntegrationTest
  API_TOKEN = "test-api-token-for-we-match"

  setup do
    ENV["WE_MATCH_API_TOKEN"] = API_TOKEN
    @group = create_group(name: "API Group")
    @topic = create_topic(name: "Leadership")
    @member_a = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @member_b = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
  end

  teardown do
    ENV.delete("WE_MATCH_API_TOKEN")
  end

  test "a request without a token is refused" do
    get api_v1_members_path

    assert_response :unauthorized
    assert_equal "Invalid or missing API token.", JSON.parse(response.body)["error"]
  end

  test "a wrong token is refused" do
    get api_v1_members_path, headers: { "Authorization" => "Bearer wrong" }

    assert_response :unauthorized
  end

  test "a bearer token is accepted" do
    get api_v1_members_path, headers: auth_headers

    assert_response :success
    assert_equal [ "Alice", "Bob" ], JSON.parse(response.body).map { |member| member["name"] }
  end

  test "an X-Api-Token header is accepted" do
    get api_v1_groups_path, headers: { "X-Api-Token" => API_TOKEN }

    assert_response :success
  end

  test "no configured token means nothing is allowed through" do
    ENV.delete("WE_MATCH_API_TOKEN")

    get api_v1_members_path, headers: auth_headers

    assert_response :unauthorized
  end

  test "matching refuses a draft cycle" do
    @cycle.update!(status: :draft)

    post run_matching_api_v1_match_cycle_path(@cycle), headers: auth_headers

    assert_response :unprocessable_entity
    assert_match "open or closed", JSON.parse(response.body)["error"]
  end

  test "matching refuses a cycle with no responses" do
    post run_matching_api_v1_match_cycle_path(@cycle), headers: auth_headers

    assert_response :unprocessable_entity
    assert_match "No responses", JSON.parse(response.body)["error"]
  end

  test "matching refuses a cycle that already ran" do
    @cycle.update!(status: :matched, matched_at: Time.current)

    post run_matching_api_v1_match_cycle_path(@cycle), headers: auth_headers

    assert_response :conflict
  end

  test "matching runs when the guards pass" do
    window = window_at(@cycle, hour: 13)
    create_response(cycle: @cycle, member: @member_a, topic: @topic, windows: [ window ])
    create_response(cycle: @cycle, member: @member_b, topic: @topic, windows: [ window ])

    post run_matching_api_v1_match_cycle_path(@cycle), headers: auth_headers

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["matches"].size
    assert_equal 0, body["unmatched_count"]
  end

  test "the cycle payload never includes the chosen topic option" do
    topic = create_topic(name: "Mentorship", options: [ "Finding a mentor" ])
    create_response(
      cycle: @cycle,
      member: @member_a,
      topic: topic,
      windows: [ window_at(@cycle) ],
      option: topic.topic_options.first
    )

    get api_v1_match_cycle_path(@cycle), headers: auth_headers

    assert_response :success
    assert_no_match "Finding a mentor", response.body
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{API_TOKEN}" }
  end
end
