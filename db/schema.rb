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

ActiveRecord::Schema[8.0].define(version: 2026_05_31_032443) do
  create_table "card_alternative_definitions", force: :cascade do |t|
    t.integer "card_id", null: false
    t.text "content", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_card_alternative_definitions_on_card_id"
  end

  create_table "card_reviews", force: :cascade do |t|
    t.integer "difficulty"
    t.datetime "date"
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_card_reviews_on_card_id"
  end

  create_table "cards", force: :cascade do |t|
    t.string "term"
    t.string "definition"
    t.integer "last_difficulty"
    t.date "last_view"
    t.integer "deck_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "definition_cursor", default: 0, null: false
    t.index ["deck_id"], name: "index_cards_on_deck_id"
  end

  create_table "decks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_decks_on_user_id"
  end

  create_table "password_resets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_hash", null: false
    t.datetime "expires_at", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_password_resets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "card_alternative_definitions", "cards"
  add_foreign_key "card_reviews", "cards"
  add_foreign_key "cards", "decks"
  add_foreign_key "decks", "users"
  add_foreign_key "password_resets", "users"
end
