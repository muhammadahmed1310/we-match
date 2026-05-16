# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_05_16_120006) do
  enable_extension "plpgsql"

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "group_id" ], name: "index_group_memberships_on_group_id"
    t.index [ "member_id", "group_id" ], name: "index_group_memberships_on_member_id_and_group_id", unique: true
    t.index [ "member_id" ], name: "index_group_memberships_on_member_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_groups_on_name", unique: true
  end

  create_table "match_cycles", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "opens_at"
    t.datetime "closes_at"
    t.datetime "matched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "group_id" ], name: "index_match_cycles_on_group_id"
  end

  create_table "match_responses", force: :cascade do |t|
    t.bigint "match_cycle_id", null: false
    t.bigint "member_id", null: false
    t.string "topic", null: false
    t.datetime "availability_start", null: false
    t.datetime "availability_end", null: false
    t.bigint "match_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "match_cycle_id", "member_id" ], name: "index_match_responses_on_match_cycle_id_and_member_id", unique: true
    t.index [ "match_cycle_id" ], name: "index_match_responses_on_match_cycle_id"
    t.index [ "match_id" ], name: "index_match_responses_on_match_id"
    t.index [ "member_id" ], name: "index_match_responses_on_member_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "match_cycle_id", null: false
    t.bigint "member_one_id", null: false
    t.bigint "member_two_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "match_cycle_id" ], name: "index_matches_on_match_cycle_id"
    t.index [ "member_one_id" ], name: "index_matches_on_member_one_id"
    t.index [ "member_two_id" ], name: "index_matches_on_member_two_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_members_on_email", unique: true
  end

  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "members"
  add_foreign_key "match_cycles", "groups"
  add_foreign_key "match_responses", "match_cycles"
  add_foreign_key "match_responses", "matches"
  add_foreign_key "match_responses", "members"
  add_foreign_key "matches", "match_cycles"
  add_foreign_key "matches", "members", column: "member_one_id"
  add_foreign_key "matches", "members", column: "member_two_id"
end
