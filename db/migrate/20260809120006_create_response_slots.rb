class CreateResponseSlots < ActiveRecord::Migration[7.2]
  class MigrationResponse < ActiveRecord::Base
    self.table_name = "match_responses"
  end

  class MigrationSlot < ActiveRecord::Base
    self.table_name = "response_slots"
  end

  def up
    create_table :response_slots do |t|
      t.references :match_response, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end

    add_index :response_slots, %i[match_response_id starts_at], unique: true
    add_index :response_slots, :starts_at

    add_column :match_cycles, :meeting_week_start, :date

    backfill_slots
    backfill_meeting_weeks

    remove_column :match_responses, :availability_start
    remove_column :match_responses, :availability_end
  end

  def down
    add_column :match_responses, :availability_start, :datetime
    add_column :match_responses, :availability_end, :datetime

    MigrationSlot.order(:match_response_id, :starts_at).each do |slot|
      MigrationResponse.where(id: slot.match_response_id)
                       .update_all(availability_start: slot.starts_at, availability_end: slot.ends_at)
    end

    MigrationResponse.where(availability_start: nil)
                     .update_all(availability_start: Time.current, availability_end: Time.current + 1.hour)
    change_column_null :match_responses, :availability_start, false
    change_column_null :match_responses, :availability_end, false

    remove_column :match_cycles, :meeting_week_start
    drop_table :response_slots
  end

  private

  # Windows used to be a free interval. Keep the intent by turning each one into
  # the 1-hour slot that starts at the top of the requested hour.
  def backfill_slots
    MigrationResponse.where.not(availability_start: nil).find_each do |response|
      starts_at = response.availability_start.change(min: 0, sec: 0, usec: 0)

      MigrationSlot.create!(
        match_response_id: response.id,
        starts_at: starts_at,
        ends_at: starts_at + 1.hour,
        created_at: Time.current,
        updated_at: Time.current
      )
    end
  end

  def backfill_meeting_weeks
    execute <<~SQL.squish
      UPDATE match_cycles
      SET meeting_week_start = date_trunc('week', COALESCE(closes_at, opens_at, created_at) + interval '7 days')::date
      WHERE meeting_week_start IS NULL
    SQL
  end
end
