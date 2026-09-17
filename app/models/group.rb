class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships
  has_many :match_cycles, dependent: :destroy
  has_many :topics, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :cycle_programme_starts_on, presence: true
  validate :cycle_programme_dates_make_sense

  before_validation :ensure_auto_cycle_on

  scope :ordered, -> { order(:name) }
  scope :auto_cycling, -> { where(auto_cycle: true) }

  def available_topics
    Topic.active.available_to(self).includes(:topic_options).ordered
  end

  def latest_cycle
    match_cycles.recent.first
  end

  def open_cycle
    match_cycles.where(status: %i[open closed]).recent.first
  end

  # Automation runs on Mondays. A Thursday start means the first possible open is
  # the next Monday on or after that date (if the group is due and has 2+ people).
  def programme_active_on?(date)
    return false if cycle_programme_starts_on.blank?
    return false if date < cycle_programme_starts_on
    return false if cycle_programme_ends_on.present? && date > cycle_programme_ends_on

    true
  end

  def programme_window_label
    if cycle_programme_ends_on.blank?
      "From #{cycle_programme_starts_on.strftime('%b %-d, %Y')} onward"
    else
      "#{cycle_programme_starts_on.strftime('%b %-d, %Y')} – #{cycle_programme_ends_on.strftime('%b %-d, %Y')}"
    end
  end

  private

  def ensure_auto_cycle_on
    self.auto_cycle = true
  end

  def cycle_programme_dates_make_sense
    return if cycle_programme_starts_on.blank? || cycle_programme_ends_on.blank?
    return if cycle_programme_ends_on >= cycle_programme_starts_on

    errors.add(:cycle_programme_ends_on, "must be on or after the matching start date")
  end
end
