class MatchCycle < ApplicationRecord
  belongs_to :group
  has_many :match_responses, dependent: :destroy
  has_many :matches, dependent: :destroy

  enum :status, { draft: 0, open: 1, closed: 2, matched: 3 }, validate: true

  validates :group, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def ready_for_matching?
    open? || closed?
  end

  def member_ids_in_group
    group.member_ids
  end
end
