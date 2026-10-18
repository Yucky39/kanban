# Columns come from gen/models/board.rb (generated from db/schema.rb).
# A board belongs to one user (user_id is the users.id); every query in the
# controllers is scoped by it, so one user can never reach another's board.
class Board
  validates :name, presence: true, length: { maximum: 100 }
end
