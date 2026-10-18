class AddPendingEmailToUsers < Cybertrain::Migration::Base
  def change
    add_column "users", "pending_email", :string
  end
end
