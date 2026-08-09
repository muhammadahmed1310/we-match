# frozen_string_literal: true

require "test_helper"

class PeopleImportTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "WE Fellows")
  end

  test "previews without writing anything" do
    csv = <<~CSV
      name,email,time_zone,groups,cohort
      Amara Okafor,amara@example.org,Africa/Lagos,WE Fellows,2026
    CSV

    result = assert_no_difference -> { Member.count } do
      PeopleImport.new(csv).preview
    end

    assert result.ok?
    assert_equal 1, result.created
    assert_equal :create, result.rows.first.action
  end

  test "creates people and memberships on commit" do
    csv = <<~CSV
      name,email,time_zone,groups,cohort
      Amara Okafor,amara@example.org,Africa/Lagos,WE Fellows,2026
    CSV

    PeopleImport.new(csv).commit!

    member = Member.find_by(email: "amara@example.org")
    assert_equal "Africa/Lagos", member.time_zone
    assert_equal [ "WE Fellows" ], member.groups.map(&:name)
    assert_equal "2026", member.group_memberships.first.cohort
  end

  test "updates an existing person matched on email" do
    create_member(name: "Old Name", email: "amara@example.org")
    csv = <<~CSV
      name,email,time_zone,groups
      Amara Okafor,AMARA@example.org,Africa/Lagos,WE Fellows
    CSV

    result = PeopleImport.new(csv).commit!

    assert_equal 1, result.updated
    member = Member.find_by(email: "amara@example.org")
    assert_equal "Amara Okafor", member.name
    assert_equal [ "WE Fellows" ], member.groups.map(&:name)
  end

  test "flags a row whose time zone is not recognised" do
    csv = <<~CSV
      name,email,time_zone
      Amara Okafor,amara@example.org,Mars/Olympus
    CSV

    result = PeopleImport.new(csv).preview

    refute result.ok?
    assert_equal 1, result.invalid
    assert_includes result.rows.first.messages.join(" "), "not recognised"
  end

  test "flags a row whose group does not exist" do
    csv = <<~CSV
      name,email,groups
      Amara Okafor,amara@example.org,Unknown Group
    CSV

    result = PeopleImport.new(csv).preview

    refute result.ok?
    assert_includes result.rows.first.messages.join(" "), "does not exist"
  end

  test "creates missing groups when asked to" do
    csv = <<~CSV
      name,email,groups
      Amara Okafor,amara@example.org,Brand New Group
    CSV

    result = PeopleImport.new(csv, create_missing_groups: true).commit!

    assert result.ok?
    assert_equal [ "Brand New Group" ], result.new_groups
    assert Group.exists?(name: "Brand New Group")
  end

  test "flags duplicate emails within the file" do
    csv = <<~CSV
      name,email
      Amara Okafor,amara@example.org
      Amara Again,amara@example.org
    CSV

    result = PeopleImport.new(csv).preview

    refute result.ok?
    assert_includes result.rows.last.messages.join(" "), "Duplicate of line 2"
  end

  test "reports a missing required column" do
    result = PeopleImport.new("full_name,email\nAmara,amara@example.org").preview

    refute result.ok?
    assert_includes result.header_error, "name"
  end

  test "reports an empty file" do
    assert_includes PeopleImport.new("").preview.header_error, "empty"
  end

  test "writes nothing when any row is invalid" do
    csv = <<~CSV
      name,email
      Amara Okafor,amara@example.org
      ,broken
    CSV

    assert_no_difference -> { Member.count } do
      PeopleImport.new(csv).commit!
    end
  end

  test "leaves an already correct row alone" do
    create_member(name: "Amara Okafor", email: "amara@example.org", time_zone: "Africa/Lagos", groups: [ @group ])
    csv = <<~CSV
      name,email,time_zone,groups
      Amara Okafor,amara@example.org,Africa/Lagos,WE Fellows
    CSV

    result = PeopleImport.new(csv).preview

    assert_equal 1, result.unchanged
  end
end
