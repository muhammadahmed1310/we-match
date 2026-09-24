# frozen_string_literal: true

# Public group join form. Finds or creates the person by email and adds them to
# the group that owns the signup token.
class GroupSignup
  Result = Struct.new(:member, :created, :added_to_group, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def initialize(group, attributes)
    @group = group
    @attributes = attributes.to_h.symbolize_keys
  end

  def call
    member = Member.find_or_initialize_by(email: normalized_email)
    was_new = member.new_record?
    already_in_group = !was_new && member.groups.exists?(id: @group.id)

    member.name = @attributes[:name].to_s.strip
    member.time_zone = @attributes[:time_zone].to_s.strip.presence || "UTC"

    unless member.valid?
      return Result.new(member: member, created: false, added_to_group: false, errors: member.errors.full_messages)
    end

    ActiveRecord::Base.transaction do
      member.save!
      member.group_memberships.find_or_create_by!(group: @group)
    end

    Result.new(
      member: member,
      created: was_new,
      added_to_group: was_new || !already_in_group,
      errors: []
    )
  rescue ActiveRecord::RecordInvalid => e
    Result.new(member: member, created: false, added_to_group: false, errors: e.record.errors.full_messages)
  end

  private

  def normalized_email
    @attributes[:email].to_s.strip.downcase
  end
end
