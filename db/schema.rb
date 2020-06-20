# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190830043855) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "acceptors", force: :cascade do |t|
    t.bigint "outgoing_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outgoing_id"], name: "index_acceptors_on_outgoing_id"
  end

  create_table "custom_group_connections", force: :cascade do |t|
    t.bigint "custom_group_id"
    t.integer "outgoing_user_id"
    t.integer "acceptor_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_group_id"], name: "index_custom_group_connections_on_custom_group_id"
  end

  create_table "custom_group_members", force: :cascade do |t|
    t.bigint "custom_group_id"
    t.integer "user_id"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notifications"
    t.boolean "blocked", default: false
    t.index ["custom_group_id"], name: "index_custom_group_members_on_custom_group_id"
  end

  create_table "custom_groups", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "username"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_custom_groups_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "friend_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.boolean "receive_notifications", default: true
    t.boolean "send_notifications", default: true
    t.boolean "user_receive_notifications", default: true
  end

  create_table "group_connections", force: :cascade do |t|
    t.bigint "program_id"
    t.integer "outgoing_user_id"
    t.integer "acceptor_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_group_connections_on_program_id"
  end

  create_table "outgoings", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "seconds"
    t.index ["user_id"], name: "index_outgoings_on_user_id"
  end

  create_table "plan_members", force: :cascade do |t|
    t.bigint "plan_id"
    t.bigint "user_id"
    t.boolean "status", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_plan_members_on_plan_id"
    t.index ["user_id"], name: "index_plan_members_on_user_id"
  end

  create_table "plan_messages", force: :cascade do |t|
    t.bigint "plan_id"
    t.bigint "user_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_message", default: false
    t.index ["plan_id"], name: "index_plan_messages_on_plan_id"
    t.index ["user_id"], name: "index_plan_messages_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "group_type"
    t.bigint "group_id"
    t.bigint "user_id"
    t.integer "activity"
    t.integer "time"
    t.integer "exploding_offer"
    t.boolean "is_happening", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_type", "group_id"], name: "index_plans_on_group_type_and_group_id"
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "program_group_members", force: :cascade do |t|
    t.bigint "program_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notifications"
    t.index ["program_id"], name: "index_program_group_members_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.string "program_name"
    t.bigint "university_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["university_id"], name: "index_programs_on_university_id"
  end

  create_table "universities", force: :cascade do |t|
    t.string "university_name"
    t.string "university_country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "university", default: true
  end

  create_table "users", force: :cascade do |t|
    t.string "phone_number"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "image"
    t.string "email"
    t.string "fullname"
    t.string "username"
    t.string "firebase_token"
    t.string "password_digest"
    t.boolean "iOS", default: false
    t.string "instagram"
    t.string "snapchat"
    t.string "twitter"
    t.integer "enrollment_date"
    t.boolean "verified"
    t.boolean "submitted"
  end

  add_foreign_key "acceptors", "outgoings"
  add_foreign_key "custom_group_connections", "custom_groups"
  add_foreign_key "custom_group_members", "custom_groups"
  add_foreign_key "custom_groups", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "group_connections", "programs"
  add_foreign_key "outgoings", "users"
  add_foreign_key "plan_members", "plans"
  add_foreign_key "plan_members", "users"
  add_foreign_key "plan_messages", "plans"
  add_foreign_key "plan_messages", "users"
  add_foreign_key "plans", "users"
  add_foreign_key "program_group_members", "programs"
  add_foreign_key "programs", "universities"
end
