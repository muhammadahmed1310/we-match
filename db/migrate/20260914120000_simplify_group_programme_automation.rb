# frozen_string_literal: true

class SimplifyGroupProgrammeAutomation < ActiveRecord::Migration[7.2]
  def up
    # Automation is always on; programme start is the control.
    change_column_default :groups, :auto_cycle, from: false, to: true

    Group.reset_column_information
    Group.find_each do |group|
      attrs = { auto_cycle: true }
      if group.cycle_programme_starts_on.blank?
        attrs[:cycle_programme_starts_on] = group.created_at&.to_date || Date.current
      end
      group.update_columns(attrs)
    end
  end

  def down
    change_column_default :groups, :auto_cycle, from: true, to: false
  end
end
