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

ActiveRecord::Schema[7.2].define(version: 2026_09_14_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "last_signed_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "cycle_invitations", force: :cascade do |t|
    t.bigint "match_cycle_id", null: false
    t.bigint "member_id", null: false
    t.string "token", null: false
    t.datetime "sent_at"
    t.datetime "responded_at"
    t.integer "send_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_cycle_id", "member_id"], name: "index_cycle_invitations_on_match_cycle_id_and_member_id", unique: true
    t.index ["match_cycle_id"], name: "index_cycle_invitations_on_match_cycle_id"
    t.index ["member_id"], name: "index_cycle_invitations_on_member_id"
    t.index ["token"], name: "index_cycle_invitations_on_token", unique: true
  end

  create_table "email_deliveries", force: :cascade do |t|
    t.string "mailer", null: false
    t.string "mailer_action", null: false
    t.string "subject"
    t.string "recipients", null: false
    t.integer "status", default: 0, null: false
    t.datetime "delivered_at"
    t.text "error_message"
    t.bigint "match_cycle_id"
    t.bigint "member_id"
    t.bigint "match_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_email_deliveries_on_created_at"
    t.index ["match_cycle_id"], name: "index_email_deliveries_on_match_cycle_id"
    t.index ["match_id"], name: "index_email_deliveries_on_match_id"
    t.index ["member_id"], name: "index_email_deliveries_on_member_id"
    t.index ["status"], name: "index_email_deliveries_on_status"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cohort"
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["member_id", "group_id"], name: "index_group_memberships_on_member_id_and_group_id", unique: true
    t.index ["member_id"], name: "index_group_memberships_on_member_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_cycle", default: true, null: false
    t.date "auto_cycle_last_opened_on"
    t.date "cycle_programme_starts_on"
    t.date "cycle_programme_ends_on"
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "match_cycles", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "opens_at"
    t.datetime "closes_at"
    t.datetime "matched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "meeting_week_start"
    t.boolean "auto_created", default: false, null: false
    t.datetime "invitations_sent_at"
    t.index ["group_id"], name: "index_match_cycles_on_group_id"
  end

  create_table "match_feedbacks", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "member_id", null: false
    t.bigint "topic_option_id"
    t.string "token", null: false
    t.boolean "did_meet"
    t.integer "value_for_time"
    t.datetime "sent_at"
    t.datetime "submitted_at"
    t.integer "send_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "member_id"], name: "index_match_feedbacks_on_match_id_and_member_id", unique: true
    t.index ["match_id"], name: "index_match_feedbacks_on_match_id"
    t.index ["member_id"], name: "index_match_feedbacks_on_member_id"
    t.index ["token"], name: "index_match_feedbacks_on_token", unique: true
    t.index ["topic_option_id"], name: "index_match_feedbacks_on_topic_option_id"
  end

  create_table "match_responses", force: :cascade do |t|
    t.bigint "match_cycle_id", null: false
    t.bigint "member_id", null: false
    t.string "legacy_topic"
    t.bigint "match_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "topic_id"
    t.bigint "topic_option_id"
    t.string "topic_option_other"
    t.index ["match_cycle_id", "member_id"], name: "index_match_responses_on_match_cycle_id_and_member_id", unique: true
    t.index ["match_cycle_id"], name: "index_match_responses_on_match_cycle_id"
    t.index ["match_id"], name: "index_match_responses_on_match_id"
    t.index ["member_id"], name: "index_match_responses_on_member_id"
    t.index ["topic_id"], name: "index_match_responses_on_topic_id"
    t.index ["topic_option_id"], name: "index_match_responses_on_topic_option_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "match_cycle_id", null: false
    t.bigint "member_one_id", null: false
    t.bigint "member_two_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "matched_slot_starts_at"
    t.bigint "topic_id"
    t.index ["match_cycle_id"], name: "index_matches_on_match_cycle_id"
    t.index ["member_one_id"], name: "index_matches_on_member_one_id"
    t.index ["member_two_id"], name: "index_matches_on_member_two_id"
    t.index ["topic_id"], name: "index_matches_on_topic_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone", default: "UTC", null: false
    t.index ["email"], name: "index_members_on_email", unique: true
  end

  create_table "response_slots", force: :cascade do |t|
    t.bigint "match_response_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_response_id", "starts_at"], name: "index_response_slots_on_match_response_id_and_starts_at", unique: true
    t.index ["match_response_id"], name: "index_response_slots_on_match_response_id"
    t.index ["starts_at"], name: "index_response_slots_on_starts_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "topic_options", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.string "label", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id", "label"], name: "index_topic_options_on_topic_id_and_label", unique: true
    t.index ["topic_id"], name: "index_topic_options_on_topic_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "group_id"
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "name"], name: "index_topics_on_group_id_and_name", unique: true
    t.index ["group_id"], name: "index_topics_on_group_id"
    t.index ["name"], name: "index_topics_on_name_when_global", unique: true, where: "(group_id IS NULL)"
  end

  add_foreign_key "cycle_invitations", "match_cycles"
  add_foreign_key "cycle_invitations", "members"
  add_foreign_key "email_deliveries", "match_cycles"
  add_foreign_key "email_deliveries", "matches"
  add_foreign_key "email_deliveries", "members"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "members"
  add_foreign_key "match_cycles", "groups"
  add_foreign_key "match_feedbacks", "matches"
  add_foreign_key "match_feedbacks", "members"
  add_foreign_key "match_feedbacks", "topic_options"
  add_foreign_key "match_responses", "match_cycles"
  add_foreign_key "match_responses", "matches"
  add_foreign_key "match_responses", "members"
  add_foreign_key "match_responses", "topic_options"
  add_foreign_key "match_responses", "topics"
  add_foreign_key "matches", "match_cycles"
  add_foreign_key "matches", "members", column: "member_one_id"
  add_foreign_key "matches", "members", column: "member_two_id"
  add_foreign_key "matches", "topics"
  add_foreign_key "response_slots", "match_responses"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "topic_options", "topics"
  add_foreign_key "topics", "groups"
end
