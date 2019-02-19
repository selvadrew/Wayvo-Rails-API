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

ActiveRecord::Schema.define(version: 20190122003948) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "acceptors", force: :cascade do |t|
    t.bigint "outgoing_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outgoing_id"], name: "index_acceptors_on_outgoing_id"
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

  create_table "program_group_members", force: :cascade do |t|
    t.bigint "program_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  add_foreign_key "feedbacks", "users"
  add_foreign_key "group_connections", "programs"
  add_foreign_key "outgoings", "users"
  add_foreign_key "program_group_members", "programs"
  add_foreign_key "programs", "universities"
end
