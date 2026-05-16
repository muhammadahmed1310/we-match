class CreateMatchResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :match_responses do |t|
      t.references :match_cycle, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.string :topic, null: false
      t.datetime :availability_start, null: false
      t.datetime :availability_end, null: false
      t.references :match, foreign_key: true

      t.timestamps
    end

    add_index :match_responses, %i[match_cycle_id member_id], unique: true
  end
end
