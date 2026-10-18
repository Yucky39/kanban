class CreateCards < Cybertrain::Migration::Base
  def change
    create_table "cards" do |t|
      t.string "title", null: false
      t.text "description"
      t.string "status", null: false
      t.integer "position", null: false
      t.references :board
      t.timestamps
    end
    add_index "cards", ["board_id", "position"]
  end
end
