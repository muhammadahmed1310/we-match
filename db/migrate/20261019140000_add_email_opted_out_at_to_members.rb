# frozen_string_literal: true

class AddEmailOptedOutAtToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :email_opted_out_at, :datetime
  end
end
