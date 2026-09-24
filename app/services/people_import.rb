# frozen_string_literal: true

require "roo"
require "json"

# Excel (.xlsx) import for the WE Community. Runs the same parsing and validation
# twice: once as a dry run, then for real inside a transaction after the CM confirms.
class PeopleImport
  REQUIRED_HEADERS = %w[name email].freeze
  OPTIONAL_HEADERS = %w[time_zone groups cohort].freeze
  ACCEPTED_HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze
  GROUP_SEPARATOR = /[;|]/

  Row = Struct.new(:line, :name, :email, :time_zone, :group_names, :cohort, :action, :messages, keyword_init: true) do
    def valid?
      action != :invalid
    end

    def to_payload
      {
        "name" => name,
        "email" => email,
        "time_zone" => time_zone,
        "groups" => group_names.join(";"),
        "cohort" => cohort
      }
    end
  end

  Result = Struct.new(:rows, :header_error, :created, :updated, :unchanged, :invalid, :new_groups, keyword_init: true) do
    def ok?
      header_error.blank? && invalid.zero?
    end

    def total
      rows.size
    end

    def payload_json
      JSON.generate(rows.map(&:to_payload))
    end
  end

  def self.from_xlsx(upload, create_missing_groups: false)
    new(read_xlsx(upload), create_missing_groups: create_missing_groups)
  end

  def self.from_payload(json_or_rows, create_missing_groups: false)
    rows = json_or_rows.is_a?(String) ? JSON.parse(json_or_rows) : json_or_rows
    new(Array(rows), create_missing_groups: create_missing_groups)
  rescue JSON::ParserError
    new([], create_missing_groups: create_missing_groups, header_error: "The import preview expired. Upload the Excel file again.")
  end

  def self.read_xlsx(upload)
    path = upload.respond_to?(:tempfile) ? upload.tempfile.path : upload.to_s
    extension = File.extname(upload.respond_to?(:original_filename) ? upload.original_filename.to_s : path).downcase

    raise ArgumentError, "Please upload an Excel file (.xlsx)." unless extension == ".xlsx"

    sheet = Roo::Excelx.new(path)
    raise ArgumentError, "The spreadsheet is empty." if sheet.last_row.nil? || sheet.last_row < 1

    headers = Array(sheet.row(1)).map { |header| normalize_header(header) }
    missing = REQUIRED_HEADERS - headers
    raise ArgumentError, "Missing required column(s): #{missing.join(', ')}. Expected #{ACCEPTED_HEADERS.join(', ')}." if missing.any?

    (2..sheet.last_row).filter_map do |line|
      values = headers.zip(Array(sheet.row(line))).to_h
      next if values.values.all? { |value| value.to_s.strip.blank? }

      {
        "name" => values["name"].to_s.strip,
        "email" => values["email"].to_s.strip.downcase,
        "time_zone" => values["time_zone"].to_s.strip.presence || "UTC",
        "groups" => values["groups"].to_s.strip,
        "cohort" => values["cohort"].to_s.strip.presence,
        "line" => line
      }
    end
  rescue Zip::Error, ArgumentError, RuntimeError => e
    raise ArgumentError, e.message
  end

  def self.normalize_header(header)
    header.to_s.strip.downcase.tr(" ", "_")
  end

  def initialize(raw_rows, create_missing_groups: false, header_error: nil)
    @raw_rows = Array(raw_rows)
    @create_missing_groups = create_missing_groups
    @header_error = header_error
  end

  def preview
    analyse
  end

  def commit!
    result = analyse
    return result unless result.ok?

    ActiveRecord::Base.transaction do
      result.rows.each { |row| apply(row) }
    end

    result
  end

  private

  def analyse
    if @header_error.present?
      return Result.new(rows: [], header_error: @header_error, created: 0, updated: 0, unchanged: 0, invalid: 0, new_groups: [])
    end

    if @raw_rows.empty?
      return Result.new(rows: [], header_error: "The spreadsheet has no data rows.", created: 0, updated: 0, unchanged: 0, invalid: 0, new_groups: [])
    end

    seen_emails = {}
    rows = []
    new_groups = []

    @raw_rows.each_with_index do |raw, index|
      row = build_row(raw, raw["line"] || raw[:line] || index + 2)
      next if row.nil?

      classify(row, seen_emails, new_groups)
      rows << row
    end

    Result.new(
      rows: rows,
      header_error: nil,
      created: rows.count { |row| row.action == :create },
      updated: rows.count { |row| row.action == :update },
      unchanged: rows.count { |row| row.action == :unchanged },
      invalid: rows.count { |row| row.action == :invalid },
      new_groups: new_groups.uniq
    )
  end

  def build_row(raw, line)
    values = raw.stringify_keys.transform_values { |value| value.to_s.strip }
    return nil if values.values_at("name", "email", "time_zone", "groups", "cohort").all?(&:blank?)

    Row.new(
      line: line,
      name: values["name"],
      email: values["email"].downcase,
      time_zone: values["time_zone"].presence || "UTC",
      group_names: values["groups"].to_s.split(GROUP_SEPARATOR).map(&:strip).reject(&:blank?),
      cohort: values["cohort"].presence,
      action: nil,
      messages: []
    )
  end

  def classify(row, seen_emails, new_groups)
    row.messages << "Name is missing." if row.name.blank?
    row.messages << "Email is missing." if row.email.blank?
    row.messages << "Email does not look like an email address." if row.email.present? && !row.email.match?(URI::MailTo::EMAIL_REGEXP)
    row.messages << "Time zone '#{row.time_zone}' is not recognised." if ActiveSupport::TimeZone[row.time_zone].nil?

    if row.email.present? && seen_emails.key?(row.email)
      row.messages << "Duplicate of line #{seen_emails[row.email]} in this file."
    elsif row.email.present?
      seen_emails[row.email] = row.line
    end

    row.group_names.each do |group_name|
      next if Group.exists?(name: group_name)

      if @create_missing_groups
        new_groups << group_name
        row.messages << "Group '#{group_name}' will be created."
      else
        row.messages << "Group '#{group_name}' does not exist."
      end
    end

    if row.messages.any? { |message| !message.end_with?("will be created.") }
      row.action = :invalid
      return
    end

    existing = row.email.present? ? Member.find_by(email: row.email) : nil

    if existing.nil?
      row.action = :create
      row.messages << "New person."
    elsif changes_for(existing, row).any?
      row.action = :update
      row.messages << "Updates: #{changes_for(existing, row).join(', ')}."
    else
      row.action = :unchanged
      row.messages << "Already up to date."
    end
  end

  def changes_for(member, row)
    changes = []
    changes << "name" if member.name != row.name
    changes << "time zone" if member.time_zone != row.time_zone

    missing_groups = row.group_names - member.groups.map(&:name)
    changes << "adds to #{missing_groups.join(', ')}" if missing_groups.any?

    changes
  end

  def apply(row)
    member = Member.find_or_initialize_by(email: row.email)
    member.name = row.name
    member.time_zone = row.time_zone
    member.save!

    row.group_names.each do |group_name|
      group = if @create_missing_groups
        Group.find_or_create_by!(name: group_name) do |new_group|
          new_group.cycle_programme_starts_on = Date.current
        end
      else
        Group.find_by!(name: group_name)
      end
      membership = member.group_memberships.find_or_initialize_by(group: group)
      membership.cohort = row.cohort if row.cohort.present?
      membership.save!
    end
  end
end
