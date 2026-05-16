class GroupMembership < ApplicationRecord
  belongs_to :member
  belongs_to :group

  validates :member_id, uniqueness: { scope: :group_id }
end
