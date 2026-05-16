class CreateMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :matches do |t|
      t.references :match_cycle, null: false, foreign_key: true
      t.references :member_one, null: false, foreign_key: { to_table: :members }
      t.references :member_two, null: false, foreign_key: { to_table: :members }

      t.timestamps
    end
  end
end
