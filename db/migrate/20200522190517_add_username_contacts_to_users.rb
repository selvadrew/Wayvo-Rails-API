class AddUsernameContactsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :username_contacts, :jsonb
  end
end
