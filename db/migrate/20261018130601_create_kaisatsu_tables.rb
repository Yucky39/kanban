class CreateKaisatsuTables < Cybertrain::Migration::Base
  def change
    create_table "kaisatsu_sessions" do |t|
      t.string "digest", null: false
      t.string "user_id", null: false
      t.integer "created_at", null: false
      t.integer "expires_at", null: false
    end
    add_index "kaisatsu_sessions", ["digest"], unique: true
    add_index "kaisatsu_sessions", ["user_id"]

    create_table "kaisatsu_tokens" do |t|
      t.string "digest", null: false
      t.string "user_id", null: false
      t.string "purpose", null: false
      t.integer "expires_at", null: false
      t.integer "used_at"
    end
    add_index "kaisatsu_tokens", ["digest"], unique: true
    add_index "kaisatsu_tokens", ["user_id"]

    create_table "kaisatsu_attempts" do |t|
      t.string "bucket", null: false
      t.integer "window_start", null: false
      t.integer "failures", null: false
    end
    add_index "kaisatsu_attempts", ["bucket"], unique: true
  end
end
