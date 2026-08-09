# frozen_string_literal: true

class Topic < ApplicationRecord
  belongs_to :group, optional: true
  has_many :topic_options, -> { order(:position, :label) }, dependent: :destroy, inverse_of: :topic
  has_many :match_responses, dependent: :restrict_with_error

  accepts_nested_attributes_for :topic_options, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: { scope: :group_id, case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :global, -> { where(group_id: nil) }
  scope :available_to, ->(group) { where(group_id: [ nil, group&.id ]) }

  def global?
    group_id.nil?
  end

  def scope_label
    global? ? "All groups" : group.name
  end

  def selectable_options
    topic_options.select(&:active?)
  end
end
