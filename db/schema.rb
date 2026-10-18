Cybertrain::Schema.define(version: "20261018130606") do |s|
  s.create_table "boards" do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  s.create_table "cards" do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", null: false
    t.integer "position", null: false
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  s.create_table "kaisatsu_attempts" do |t|
    t.string "bucket", null: false
    t.integer "window_start", null: false
    t.integer "failures", null: false
  end

  s.create_table "kaisatsu_sessions" do |t|
    t.string "digest", null: false
    t.string "user_id", null: false
    t.integer "created_at", null: false
    t.integer "expires_at", null: false
  end

  s.create_table "kaisatsu_tokens" do |t|
    t.string "digest", null: false
    t.string "user_id", null: false
    t.string "purpose", null: false
    t.integer "expires_at", null: false
    t.integer "used_at"
  end

  s.create_table "users" do |t|
    t.string "email", null: false
    t.string "password_hash", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "email_verified_at"
    t.string "pending_email"
  end

  s.add_index "boards", ["user_id"], name: "index_boards_on_user_id"
  s.add_index "cards", ["board_id"], name: "index_cards_on_board_id"
  s.add_index "cards", ["board_id", "position"], name: "index_cards_on_board_id_and_position"
  s.add_index "kaisatsu_attempts", ["bucket"], unique: true, name: "index_kaisatsu_attempts_on_bucket"
  s.add_index "kaisatsu_sessions", ["digest"], unique: true, name: "index_kaisatsu_sessions_on_digest"
  s.add_index "kaisatsu_sessions", ["user_id"], name: "index_kaisatsu_sessions_on_user_id"
  s.add_index "kaisatsu_tokens", ["digest"], unique: true, name: "index_kaisatsu_tokens_on_digest"
  s.add_index "kaisatsu_tokens", ["user_id"], name: "index_kaisatsu_tokens_on_user_id"
  s.add_index "users", ["email"], unique: true, name: "index_users_on_email"

  s.add_foreign_key "cards", "boards", column: "board_id"
end
