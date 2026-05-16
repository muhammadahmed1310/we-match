class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships
  has_many :match_cycles, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
