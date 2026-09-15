# frozen_string_literal: true

require "test_helper"

class PeopleImportTest < ActiveSupport::TestCase
  setup do
    @group = create_group(name: "WE Fellows")
  end

  test "previews without writing anything" do
    rows = import_rows(
      name: "Amara Okafor", email: "amara@example.org", time_zone: "Africa/Lagos", groups: "WE Fellows", cohort: "2026"
    )

    result = assert_no_difference -> { Member.count } do
      PeopleImport.new(rows).preview
    end

    assert result.ok?
    assert_equal 1, result.created
    assert_equal :create, result.rows.first.action
  end

  test "creates people and memberships on commit" do
    rows = import_rows(
      name: "Amara Okafor", email: "amara@example.org", time_zone: "Africa/Lagos", groups: "WE Fellows", cohort: "2026"
    )

    PeopleImport.new(rows).commit!

    member = Member.find_by(email: "amara@example.org")
    assert_equal "Africa/Lagos", member.time_zone
    assert_equal [ "WE Fellows" ], member.groups.map(&:name)
    assert_equal "2026", member.group_memberships.first.cohort
  end

  test "updates an existing person matched on email" do
    create_member(name: "Old Name", email: "amara@example.org")
    rows = import_rows(
      name: "Amara Okafor", email: "AMARA@example.org", time_zone: "Africa/Lagos", groups: "WE Fellows"
    )

    result = PeopleImport.new(rows).commit!

    assert_equal 1, result.updated
    member = Member.find_by(email: "amara@example.org")
    assert_equal "Amara Okafor", member.name
    assert_equal [ "WE Fellows" ], member.groups.map(&:name)
  end

  test "flags a row whose time zone is not recognised" do
    rows = import_rows(name: "Amara Okafor", email: "amara@example.org", time_zone: "Mars/Olympus")

    result = PeopleImport.new(rows).preview

    refute result.ok?
    assert_equal 1, result.invalid
    assert_includes result.rows.first.messages.join(" "), "not recognised"
  end

  test "flags a row whose group does not exist" do
    rows = import_rows(name: "Amara Okafor", email: "amara@example.org", groups: "Unknown Group")

    result = PeopleImport.new(rows).preview

    refute result.ok?
    assert_includes result.rows.first.messages.join(" "), "does not exist"
  end

  test "creates missing groups when asked to" do
    rows = import_rows(name: "Amara Okafor", email: "amara@example.org", groups: "Brand New Group")

    result = PeopleImport.new(rows, create_missing_groups: true).commit!

    assert result.ok?
    assert_equal [ "Brand New Group" ], result.new_groups
    assert Group.exists?(name: "Brand New Group")
  end

  test "flags duplicate emails within the file" do
    rows = import_rows(
      { name: "Amara Okafor", email: "amara@example.org" },
      { name: "Amara Again", email: "amara@example.org" }
    )

    result = PeopleImport.new(rows).preview

    refute result.ok?
    assert_includes result.rows.last.messages.join(" "), "Duplicate of line"
  end

  test "reads an uploaded xlsx workbook" do
    upload = xlsx_upload([
      { "name" => "Amara Okafor", "email" => "amara@example.org", "time_zone" => "Africa/Lagos", "groups" => "WE Fellows", "cohort" => "2026" }
    ])

    result = PeopleImport.from_xlsx(upload).commit!

    assert result.ok?
    assert Member.exists?(email: "amara@example.org")
  end

  test "rejects a missing required column in xlsx" do
    upload = xlsx_upload([ { "full_name" => "Amara", "email" => "amara@example.org" } ])

    error = assert_raises(ArgumentError) { PeopleImport.read_xlsx(upload) }
    assert_includes error.message, "name"
  end

  test "writes nothing when any row is invalid" do
    rows = import_rows(
      { name: "Amara Okafor", email: "amara@example.org" },
      { name: "", email: "broken" }
    )

    assert_no_difference -> { Member.count } do
      PeopleImport.new(rows).commit!
    end
  end

  test "leaves an already correct row alone" do
    create_member(name: "Amara Okafor", email: "amara@example.org", time_zone: "Africa/Lagos", groups: [ @group ])
    rows = import_rows(
      name: "Amara Okafor", email: "amara@example.org", time_zone: "Africa/Lagos", groups: "WE Fellows"
    )

    result = PeopleImport.new(rows).preview

    assert_equal 1, result.unchanged
  end
end
