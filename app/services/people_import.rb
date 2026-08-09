# frozen_string_literal: true

require "csv"

# CSV import for the WE Community. Runs the exact same parsing and validation twice:
# once as a dry run that only reports what would happen, and once for real inside a
# transaction, so a CM can see every problem before anything is written.
class PeopleImport
  REQUIRED_HEADERS = %w[name email].freeze
  OPTIONAL_HEADERS = %w[time_zone groups cohort].freeze
  GROUP_SEPARATOR = /[;|]/

  Row = Struct.new(:line, :name, :email, :time_zone, :group_names, :cohort, :action, :messages, keyword_init: true) do
    def valid?
      action != :invalid
    end
  end

  Result = Struct.new(:rows, :header_error, :created, :updated, :unchanged, :invalid, :new_groups, keyword_init: true) do
    def ok?
      header_error.blank? && invalid.zero?
    end

    def total
      rows.size
    end
  end

  def initialize(csv_text, create_missing_groups: false)
    @csv_text = csv_text.to_s
    @create_missing_groups = create_missing_groups
  end

  def preview
    analyse
  end

  # Refuses partial imports: a half-imported file is harder to reason about than a
  # rejected one.
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
    table = parse_table
    return Result.new(rows: [], header_error: @header_error, created: 0, updated: 0, unchanged: 0, invalid: 0, new_groups: []) if @header_error

    seen_emails = {}
    rows = []
    new_groups = []

    table.each_with_index do |csv_row, index|
      row = build_row(csv_row, index + 2)
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

  def parse_table
    if @csv_text.strip.empty?
      @header_error = "The file is empty."
      return []
    end

    table = CSV.parse(@csv_text, headers: true, header_converters: ->(header) { header.to_s.strip.downcase.tr(" ", "_") })
    headers = table.headers.compact
    missing = REQUIRED_HEADERS - headers

    if missing.any?
      @header_error = "Missing required column(s): #{missing.join(', ')}. Expected #{(REQUIRED_HEADERS + OPTIONAL_HEADERS).join(', ')}."
      return []
    end

    table
  rescue CSV::MalformedCSVError => e
    @header_error = "That file could not be read as CSV (#{e.message})."
    []
  end

  def build_row(csv_row, line)
    values = csv_row.to_h.transform_values { |value| value.to_s.strip }
    return nil if values.values.all?(&:blank?)

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
      group = @create_missing_groups ? Group.find_or_create_by!(name: group_name) : Group.find_by!(name: group_name)
      membership = member.group_memberships.find_or_initialize_by(group: group)
      membership.cohort = row.cohort if row.cohort.present?
      membership.save!
    end
  end
end
