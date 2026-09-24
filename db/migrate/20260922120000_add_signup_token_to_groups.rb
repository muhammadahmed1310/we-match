# frozen_string_literal: true

class AddSignupTokenToGroups < ActiveRecord::Migration[7.2]
  # Keep migration independent of app model callbacks/validations.
  class Group < ActiveRecord::Base
  end

  def up
    add_column :groups, :signup_token, :string

    say_with_time "backfill signup_token for existing groups" do
      Group.reset_column_information
      Group.find_each do |group|
        next if group.signup_token.present?

        group.update_columns(signup_token: unique_signup_token)
      end
    end

    change_column_null :groups, :signup_token, false
    add_index :groups, :signup_token, unique: true
  end

  def down
    remove_index :groups, :signup_token
    remove_column :groups, :signup_token
  end

  private

  def unique_signup_token
    loop do
      token = SecureRandom.urlsafe_base64(24)
      break token unless Group.exists?(signup_token: token)
    end
  end
end
