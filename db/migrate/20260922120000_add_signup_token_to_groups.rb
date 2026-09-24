# frozen_string_literal: true

class AddSignupTokenToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :signup_token, :string, null: false
    add_index :groups, :signup_token, unique: true
  end
end
