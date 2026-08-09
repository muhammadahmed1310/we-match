class MatchResponse < ApplicationRecord
  MAX_SLOTS = 2

  belongs_to :match_cycle
  belongs_to :member
  belongs_to :match, optional: true
  belongs_to :topic
  belongs_to :topic_option, optional: true

  # autosave so a changed selection removes the slots it replaced.
  has_many :response_slots, -> { order(:starts_at) }, dependent: :destroy, inverse_of: :match_response, autosave: true

  # Local time zone and window picks arrive from the form as plain strings; slots
  # are rebuilt from them once every attribute is assigned.
  attr_writer :time_zone, :slot_selections

  before_validation :rebuild_response_slots
  after_save :persist_member_time_zone

  validates :member_id, uniqueness: { scope: :match_cycle_id }
  validates :topic_option_other, length: { maximum: 200 }
  validate :member_belongs_to_cycle_group
  validate :topic_available_to_cycle_group
  validate :topic_option_belongs_to_topic
  validate :slot_count_within_limits
  validate :slot_selections_are_offered

  scope :unmatched, -> { where(match_id: nil) }
  scope :matched, -> { where.not(match_id: nil) }

  def matched?
    match_id.present?
  end

  def time_zone
    @time_zone.presence || member&.time_zone.presence || "UTC"
  end

  def slot_selections
    return @slot_selections if @slot_selections

    windows = meeting_windows
    response_slots.map { |slot| windows.selection_for(slot.starts_at) }.compact
  end

  def slot_starts_at_values
    response_slots.map(&:starts_at)
  end

  def slot_labels(zone = time_zone)
    response_slots.map { |slot| slot.label(zone) }
  end

  # The chosen option is insight data. It is deliberately excluded from anything
  # sent to the other person in the pair.
  def insight_label
    topic_option_other.presence || topic_option&.label
  end

  def meeting_windows
    MeetingWindows.new(match_cycle, time_zone: time_zone)
  end

  private

  def rebuild_response_slots
    return if @slot_selections.nil?

    windows = meeting_windows
    starts = Array(@slot_selections).map(&:to_s).reject(&:blank?).uniq.map { |selection| windows.parse(selection) }.compact.uniq

    response_slots.each { |slot| slot.mark_for_destruction unless starts.include?(slot.starts_at) }
    existing = response_slots.reject(&:marked_for_destruction?).map(&:starts_at)
    (starts - existing).each { |starts_at| response_slots.build(starts_at: starts_at) }
  end

  def persist_member_time_zone
    return if @time_zone.blank? || member.blank?
    return if member.time_zone == @time_zone
    return unless ActiveSupport::TimeZone[@time_zone]

    member.update_column(:time_zone, @time_zone)
  end

  def member_belongs_to_cycle_group
    return if member.blank? || match_cycle.blank?

    unless match_cycle.member_ids_in_group.include?(member_id)
      errors.add(:base, "This person must belong to the match cycle's group")
    end
  end

  def topic_available_to_cycle_group
    return if topic.blank? || match_cycle.blank?
    return if topic.global? || topic.group_id == match_cycle.group_id

    errors.add(:topic, "is not available to this group")
  end

  def topic_option_belongs_to_topic
    return if topic_option.blank?

    errors.add(:topic_option, "does not belong to the selected topic") if topic_option.topic_id != topic_id
  end

  def slot_count_within_limits
    live_slots = response_slots.reject(&:marked_for_destruction?)

    if live_slots.empty?
      errors.add(:base, "Choose at least one 1-hour window")
    elsif live_slots.size > MAX_SLOTS
      errors.add(:base, "Choose at most #{MAX_SLOTS} 1-hour windows")
    end
  end

  def slot_selections_are_offered
    return if @slot_selections.nil?

    windows = meeting_windows
    invalid = Array(@slot_selections).map(&:to_s).reject(&:blank?).reject { |selection| windows.valid_selection?(selection) }
    return if invalid.empty?

    errors.add(:base, "One of the chosen windows is not offered for this cycle")
  end
end
