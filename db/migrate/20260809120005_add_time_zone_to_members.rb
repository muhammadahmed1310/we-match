class AddTimeZoneToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :time_zone, :string, null: false, default: "UTC"
    add_column :group_memberships, :cohort, :string
  end
end
