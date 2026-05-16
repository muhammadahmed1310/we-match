class MatchResponse < ApplicationRecord
  belongs_to :match_cycle
  belongs_to :member
  belongs_to :match, optional: true

  validates :topic, presence: true
  validates :availability_start, :availability_end, presence: true
  validates :member_id, uniqueness: { scope: :match_cycle_id }
  validate :availability_window_valid
  validate :member_belongs_to_cycle_group

  scope :unmatched, -> { where(match_id: nil) }

  def matched?
    match_id.present?
  end

  private

  def availability_window_valid
    return if availability_start.blank? || availability_end.blank?

    if availability_end <= availability_start
      errors.add(:availability_end, "must be after availability start")
    end
  end

  def member_belongs_to_cycle_group
    return if member.blank? || match_cycle.blank?

    unless match_cycle.member_ids_in_group.include?(member_id)
      errors.add(:member, "must belong to the match cycle's group")
    end
  end
end
