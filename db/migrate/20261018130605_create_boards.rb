class CreateBoards < Cybertrain::Migration::Base
  def change
    create_table "boards" do |t|
      t.string "name", null: false
      t.integer "user_id", null: false
      t.timestamps
    end
    add_index "boards", ["user_id"]
  end
end
