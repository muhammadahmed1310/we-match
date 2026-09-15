# frozen_string_literal: true

class AddCycleProgrammeDatesToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :cycle_programme_starts_on, :date
    add_column :groups, :cycle_programme_ends_on, :date
  end
end
