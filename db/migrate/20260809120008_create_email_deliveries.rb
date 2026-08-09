class CreateEmailDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :email_deliveries do |t|
      t.string :mailer, null: false
      t.string :mailer_action, null: false
      t.string :subject
      t.string :recipients, null: false
      t.integer :status, null: false, default: 0
      t.datetime :delivered_at
      t.text :error_message
      t.references :match_cycle, foreign_key: true
      t.references :member, foreign_key: true
      t.references :match, foreign_key: true

      t.timestamps
    end

    add_index :email_deliveries, :created_at
    add_index :email_deliveries, :status
  end
end
