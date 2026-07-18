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

ActiveRecord::Schema[8.1].define(version: 2026_07_18_030438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "bike_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "denial_reason"
    t.bigint "distribution_id"
    t.date "due_date", null: false
    t.string "phone", null: false
    t.bigint "production_id", null: false
    t.string "requestor_name", null: false
    t.integer "status", default: 1, null: false
    t.integer "status_before_archival"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["distribution_id"], name: "index_bike_requests_on_distribution_id"
    t.index ["production_id"], name: "index_bike_requests_on_production_id"
    t.index ["status"], name: "index_bike_requests_on_status"
    t.index ["user_id"], name: "index_bike_requests_on_user_id"
  end

  create_table "bikes", force: :cascade do |t|
    t.integer "age"
    t.bigint "bike_request_id", null: false
    t.integer "bike_type", default: 0, null: false
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.string "height"
    t.string "name"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["bike_request_id"], name: "index_bikes_on_bike_request_id"
  end

  create_table "distributions", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "donors", force: :cascade do |t|
    t.string "address"
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "mobile"
    t.bigint "production_id", null: false
    t.datetime "updated_at", null: false
    t.index ["production_id"], name: "index_donors_on_production_id"
  end

  create_table "production_inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "helmets", default: 0, null: false
    t.integer "locks", default: 0, null: false
    t.bigint "production_id", null: false
    t.datetime "updated_at", null: false
    t.index ["production_id"], name: "index_production_inventories_on_production_id"
  end

  create_table "productions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_distributions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "distribution_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["distribution_id"], name: "index_user_distributions_on_distribution_id"
    t.index ["user_id", "distribution_id"], name: "index_user_distributions_on_user_id_and_distribution_id", unique: true
    t.index ["user_id"], name: "index_user_distributions_on_user_id"
  end

  create_table "user_productions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "production_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["production_id"], name: "index_user_productions_on_production_id"
    t.index ["user_id", "production_id"], name: "index_user_productions_on_user_id_and_production_id", unique: true
    t.index ["user_id"], name: "index_user_productions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email"], name: "index_users_on_email_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["name"], name: "index_users_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  add_foreign_key "bike_requests", "distributions"
  add_foreign_key "bike_requests", "productions"
  add_foreign_key "bike_requests", "users"
  add_foreign_key "bikes", "bike_requests"
  add_foreign_key "donors", "productions"
  add_foreign_key "production_inventories", "productions"
  add_foreign_key "user_distributions", "distributions"
  add_foreign_key "user_distributions", "users"
  add_foreign_key "user_productions", "productions"
  add_foreign_key "user_productions", "users"
end
