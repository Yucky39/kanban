# Columns and the board association come from gen/models/card.rb.
class Card
  STATUSES = ["todo", "doing", "done"]

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 2000 }
end
