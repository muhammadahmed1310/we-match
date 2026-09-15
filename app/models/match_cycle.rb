class MatchCycle < ApplicationRecord
  belongs_to :group
  has_many :match_responses, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :cycle_invitations, dependent: :destroy
  has_many :email_deliveries, dependent: :nullify

  enum :status, { draft: 0, open: 1, closed: 2, matched: 3 }, validate: true

  validates :group, presence: true
  validate :closes_after_opens

  before_validation :set_default_meeting_week

  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: %i[draft open closed]) }

  def self.default_meeting_week_start(from = Date.current)
    (from + 7).beginning_of_week(:monday)
  end

  # Same rhythm as automation: open now, close in ~3 days, meeting week = the week after.
  def self.manual_defaults(from: Time.current)
    moment = from.change(sec: 0)
    {
      status: :draft,
      opens_at: moment.beginning_of_hour,
      closes_at: moment.beginning_of_hour.advance(days: 3).change(hour: 17, min: 0, sec: 0),
      meeting_week_start: default_meeting_week_start(moment.to_date)
    }
  end

  def ready_for_matching?
    open? || closed?
  end

  # Windows only accept responses while the cycle is open and inside its dates.
  def accepting_responses?
    return false if matched?
    return false if draft?
    return false if closed?
    return false if opens_at.present? && Time.current < opens_at
    return false if closes_at.present? && Time.current > closes_at

    true
  end

  def response_window_closed?
    closes_at.present? && Time.current > closes_at
  end

  def member_ids_in_group
    group.member_ids
  end

  def invited_count
    cycle_invitations.count
  end

  def responded_count
    match_responses.count
  end

  def response_rate
    invited = invited_count.positive? ? invited_count : group.members.count
    return 0.0 if invited.zero?

    (responded_count.to_f / invited * 100).round(1)
  end

  def unmatched_responses
    match_responses.unmatched
  end

  def meeting_week_range
    start = meeting_week_start || self.class.default_meeting_week_start
    start..(start + 6)
  end

  def label
    "#{group.name} — #{created_at&.strftime('%b %-d, %Y') || 'new cycle'}"
  end

  private

  def set_default_meeting_week
    self.meeting_week_start ||= self.class.default_meeting_week_start((closes_at || Time.current).to_date)
  end

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank?

    errors.add(:closes_at, "must be after the opening date") if closes_at <= opens_at
  end
end
