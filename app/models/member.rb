class Member < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :match_responses, dependent: :destroy
  has_many :matches_as_one, class_name: "Match", foreign_key: :member_one_id, dependent: :destroy, inverse_of: :member_one
  has_many :matches_as_two, class_name: "Match", foreign_key: :member_two_id, dependent: :destroy, inverse_of: :member_two

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def matches
    Match.where("member_one_id = ? OR member_two_id = ?", id, id)
  end
end
