class Member < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :match_responses, dependent: :destroy
  has_many :cycle_invitations, dependent: :destroy
  has_many :matches_as_one, class_name: "Match", foreign_key: :member_one_id, dependent: :destroy, inverse_of: :member_one
  has_many :matches_as_two, class_name: "Match", foreign_key: :member_two_id, dependent: :destroy, inverse_of: :member_two

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :time_zone, presence: true
  validate :time_zone_is_recognised

  def matches
    Match.where("member_one_id = ? OR member_two_id = ?", id, id)
  end

  def partner_ids
    matches.pluck(:member_one_id, :member_two_id).flatten.uniq - [ id ]
  end

  def time_zone_object
    ActiveSupport::TimeZone[time_zone] || ActiveSupport::TimeZone["UTC"]
  end

  private

  # Zones are stored as IANA identifiers ("Asia/Karachi") so the value the browser
  # reports can be saved as-is.
  def time_zone_is_recognised
    return if time_zone.blank?

    errors.add(:time_zone, "is not a recognised time zone") if ActiveSupport::TimeZone[time_zone].nil?
  end
end
