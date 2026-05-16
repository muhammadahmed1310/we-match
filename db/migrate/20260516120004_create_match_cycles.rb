class CreateMatchCycles < ActiveRecord::Migration[7.2]
  def change
    create_table :match_cycles do |t|
      t.references :group, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :opens_at
      t.datetime :closes_at
      t.datetime :matched_at

      t.timestamps
    end
  end
end
