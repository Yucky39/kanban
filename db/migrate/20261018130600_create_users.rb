class CreateUsers < Cybertrain::Migration::Base
  def change
    create_table "users" do |t|
      t.string "email", null: false
      t.string "password_hash", null: false
      t.timestamps
    end
    add_index "users", ["email"], unique: true
  end
end
