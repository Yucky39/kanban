class AddEmailVerifiedAtToUsers < Cybertrain::Migration::Base
  def change
    add_column "users", "email_verified_at", :integer
  end
end
