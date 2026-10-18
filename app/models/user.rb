# Columns come from gen/models/user.rb (generated from db/schema.rb).
class User
  validates :email, presence: true, length: { maximum: 254 }
  validates :password_hash, presence: true
end
