class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships
  has_many :match_cycles, dependent: :destroy
  has_many :topics, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }
  scope :auto_cycling, -> { where(auto_cycle: true) }

  def available_topics
    Topic.active.available_to(self).ordered
  end

  def latest_cycle
    match_cycles.recent.first
  end

  def open_cycle
    match_cycles.where(status: %i[open closed]).recent.first
  end
end
