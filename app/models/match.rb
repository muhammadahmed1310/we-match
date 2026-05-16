class Match < ApplicationRecord
  belongs_to :match_cycle
  belongs_to :member_one, class_name: "Member"
  belongs_to :member_two, class_name: "Member"
  has_many :match_responses, dependent: :nullify

  validate :members_are_distinct
  validate :members_belong_to_cycle_group
  validate :members_not_already_matched_in_cycle

  def pair_label
    "#{member_one.name} & #{member_two.name}"
  end

  private

  def members_are_distinct
    return if member_one_id.blank? || member_two_id.blank?

    if member_one_id == member_two_id
      errors.add(:member_two, "must be different from member one")
    end
  end

  def members_belong_to_cycle_group
    return if match_cycle.blank?

    group_member_ids = match_cycle.member_ids_in_group
    [ member_one_id, member_two_id ].each do |member_id|
      next if member_id.blank?

      unless group_member_ids.include?(member_id)
        errors.add(:base, "both members must belong to the cycle's group")
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
        errors.add(:base, "one or both members are already matched in this cycle")
        break
      end
    end
  end
end
