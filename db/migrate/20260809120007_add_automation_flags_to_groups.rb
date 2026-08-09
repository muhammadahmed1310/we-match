class AddAutomationFlagsToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :auto_cycle, :boolean, null: false, default: false
    add_column :groups, :auto_cycle_last_opened_on, :date
    add_column :match_cycles, :auto_created, :boolean, null: false, default: false
    add_column :match_cycles, :invitations_sent_at, :datetime
  end
end
