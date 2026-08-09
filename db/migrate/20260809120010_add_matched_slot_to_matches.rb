class AddMatchedSlotToMatches < ActiveRecord::Migration[7.2]
  def change
    add_column :matches, :matched_slot_starts_at, :datetime
    add_reference :matches, :topic, foreign_key: true
  end
end
