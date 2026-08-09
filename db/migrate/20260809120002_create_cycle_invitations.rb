class CreateCycleInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :cycle_invitations do |t|
      t.references :match_cycle, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :sent_at
      t.datetime :responded_at
      t.integer :send_count, null: false, default: 0

      t.timestamps
    end

    add_index :cycle_invitations, :token, unique: true
    add_index :cycle_invitations, %i[match_cycle_id member_id], unique: true
  end
end
