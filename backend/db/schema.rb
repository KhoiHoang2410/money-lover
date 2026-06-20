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

ActiveRecord::Schema[8.0].define(version: 2026_06_20_000020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "envelope_allocations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "envelope_id", null: false
    t.date "month", null: false
    t.bigint "allocation_minor_units", default: 0, null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["envelope_id", "month"], name: "index_envelope_allocations_on_envelope_id_and_month", unique: true
    t.index ["envelope_id"], name: "index_envelope_allocations_on_envelope_id"
    t.index ["user_id", "month"], name: "index_envelope_allocations_on_user_id_and_month"
    t.index ["user_id"], name: "index_envelope_allocations_on_user_id"
  end

  create_table "envelopes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "icon"
    t.boolean "is_reserve", default: false, null: false
    t.string "currency", null: false
    t.bigint "allocation_minor_units", default: 0, null: false
    t.bigint "weekly_cap_minor_units"
    t.bigint "monthly_cap_minor_units"
    t.bigint "carried_minor_units", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_envelopes_on_user_id"
    t.index ["user_id"], name: "index_envelopes_one_reserve_per_user", unique: true, where: "is_reserve"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "icon"
    t.bigint "target_minor_units", null: false
    t.string "currency", default: "VND", null: false
    t.integer "start_year"
    t.integer "start_month"
    t.integer "end_year"
    t.integer "end_month"
    t.jsonb "schedule", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_id"], name: "index_identities_on_provider_and_external_id", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "rate_overrides", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "key", null: false
    t.decimal "value", precision: 30, scale: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_rate_overrides_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_rate_overrides_on_user_id"
  end

  create_table "rates", force: :cascade do |t|
    t.string "key", null: false
    t.decimal "value", precision: 30, scale: 10, null: false
    t.string "source"
    t.datetime "fetched_at"
    t.boolean "stale", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_rates_on_key", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.string "icon"
    t.string "logo"
    t.string "currency", null: false
    t.bigint "opening_minor_units"
    t.decimal "opening_quantity", precision: 30, scale: 10
    t.string "holding_unit"
    t.string "ticker"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind"], name: "index_sources_on_user_id_and_kind"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.bigint "source_id", null: false
    t.bigint "destination_id"
    t.bigint "amount_minor_units", null: false
    t.string "currency", null: false
    t.bigint "destination_amount_minor_units"
    t.string "destination_currency"
    t.decimal "manual_rate", precision: 30, scale: 10
    t.bigint "fee_minor_units"
    t.decimal "trade_quantity", precision: 30, scale: 10
    t.string "trade_direction"
    t.bigint "envelope_id"
    t.bigint "goal_id"
    t.string "note"
    t.date "occurred_on", null: false
    t.boolean "backfill", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_transactions_on_destination_id"
    t.index ["envelope_id"], name: "index_transactions_on_envelope_id"
    t.index ["source_id"], name: "index_transactions_on_source_id"
    t.index ["user_id", "kind"], name: "index_transactions_on_user_id_and_kind"
    t.index ["user_id", "occurred_on"], name: "index_transactions_on_user_id_and_occurred_on"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "timezone", default: "Asia/Ho_Chi_Minh", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "envelope_allocations", "envelopes"
  add_foreign_key "envelope_allocations", "users"
  add_foreign_key "envelopes", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "rate_overrides", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "sources", "users"
  add_foreign_key "transactions", "sources"
  add_foreign_key "transactions", "sources", column: "destination_id"
  add_foreign_key "transactions", "users"
end
