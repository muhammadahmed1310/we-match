class Member < ApplicationRecord
  EMAIL_OPT_OUT_PURPOSE = "email_opt_out"

  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :match_responses, dependent: :destroy
  has_many :cycle_invitations, dependent: :destroy
  has_many :match_feedbacks, dependent: :destroy
  has_many :email_deliveries, dependent: :nullify
  has_many :matches_as_one, class_name: "Match", foreign_key: :member_one_id, dependent: :destroy, inverse_of: :member_one
  has_many :matches_as_two, class_name: "Match", foreign_key: :member_two_id, dependent: :destroy, inverse_of: :member_two

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :time_zone, presence: true
  validate :time_zone_is_recognised

  scope :receives_cycle_emails, -> { where(email_opted_out_at: nil) }

  def matches
    Match.where("member_one_id = ? OR member_two_id = ?", id, id)
  end

  def partner_ids
    matches.pluck(:member_one_id, :member_two_id).flatten.uniq - [ id ]
  end

  def time_zone_object
    ActiveSupport::TimeZone[time_zone] || ActiveSupport::TimeZone["UTC"]
  end

  def receives_cycle_emails?
    email_opted_out_at.blank?
  end

  def opted_out_of_cycle_emails?
    !receives_cycle_emails?
  end

  def opt_out_of_cycle_emails!
    update!(email_opted_out_at: Time.current) if receives_cycle_emails?
  end

  def opt_in_to_cycle_emails!
    update!(email_opted_out_at: nil) if opted_out_of_cycle_emails?
  end

  def email_preferences_token
    signed_id(purpose: EMAIL_OPT_OUT_PURPOSE)
  end

  def email_preferences_url
    Rails.application.routes.url_helpers.email_preferences_url(
      token: email_preferences_token,
      **Rails.application.config.action_mailer.default_url_options.to_h
    )
  end

  def self.find_by_email_preferences_token(token)
    find_signed(token, purpose: EMAIL_OPT_OUT_PURPOSE)
  end

  private

  # Zones are stored as IANA identifiers ("Asia/Karachi") so the value the browser
  # reports can be saved as-is.
  def time_zone_is_recognised
    return if time_zone.blank?

    errors.add(:time_zone, "is not a recognised time zone") if ActiveSupport::TimeZone[time_zone].nil?
  end
end
