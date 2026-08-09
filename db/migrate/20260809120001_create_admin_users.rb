class CreateAdminUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :last_signed_in_at

      t.timestamps
    end

    add_index :admin_users, :email, unique: true
  end
end
