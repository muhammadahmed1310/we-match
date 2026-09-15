class Match < ApplicationRecord
  belongs_to :match_cycle
  belongs_to :member_one, class_name: "Member"
  belongs_to :member_two, class_name: "Member"
  belongs_to :topic, optional: true
  has_many :match_responses, dependent: :nullify
  has_many :match_feedbacks, dependent: :destroy
  has_many :email_deliveries, dependent: :nullify

  validate :members_are_distinct
  validate :members_belong_to_cycle_group
  validate :members_not_already_matched_in_cycle

  scope :for_pair, lambda { |member_one_id, member_two_id|
    where(member_one_id: member_one_id, member_two_id: member_two_id)
      .or(where(member_one_id: member_two_id, member_two_id: member_one_id))
  }

  def pair_label
    "#{member_one.name} & #{member_two.name}"
  end

  def member_ids
    [ member_one_id, member_two_id ]
  end

  def slot_label_for(member)
    return nil if matched_slot_starts_at.blank?

    zone = member&.time_zone.presence || "UTC"
    local = matched_slot_starts_at.in_time_zone(zone)
    "#{local.strftime('%a %b %-d, %H:%M')}–#{local.advance(hours: 1).strftime('%H:%M %Z')}"
  end

  def slot_label_utc
    return nil if matched_slot_starts_at.blank?

    utc = matched_slot_starts_at.utc
    "#{utc.strftime('%a %b %-d, %H:%M')}–#{(utc + 1.hour).strftime('%H:%M')} UTC"
  end

  private

  def members_are_distinct
    return if member_one_id.blank? || member_two_id.blank?

    if member_one_id == member_two_id
      errors.add(:base, "A match must connect two different people")
    end
  end

  def members_belong_to_cycle_group
    return if match_cycle.blank?

    group_member_ids = match_cycle.member_ids_in_group
    [ member_one_id, member_two_id ].each do |member_id|
      next if member_id.blank?

      unless group_member_ids.include?(member_id)
        errors.add(:base, "both people must belong to the cycle's group")
        break
      end
    end
  end

  def members_not_already_matched_in_cycle
    return if match_cycle.blank? || member_one_id.blank? || member_two_id.blank?

    existing = match_cycle.matches.where.not(id: id)
    member_ids = [ member_one_id, member_two_id ]

    existing.each do |existing_match|
      existing_ids = [ existing_match.member_one_id, existing_match.member_two_id ]
      if (member_ids & existing_ids).any?
        errors.add(:base, "one or both people are already matched in this cycle")
        break
      end
    end
  end
end
