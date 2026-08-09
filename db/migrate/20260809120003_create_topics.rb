class CreateTopics < ActiveRecord::Migration[7.2]
  def change
    create_table :topics do |t|
      t.string :name, null: false
      t.text :description
      t.references :group, foreign_key: true
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :topics, %i[group_id name], unique: true
    # Postgres treats NULLs as distinct, so group-wide topics need their own index.
    add_index :topics, :name, unique: true, where: "group_id IS NULL", name: "index_topics_on_name_when_global"

    create_table :topic_options do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :label, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :topic_options, %i[topic_id label], unique: true
  end
end
