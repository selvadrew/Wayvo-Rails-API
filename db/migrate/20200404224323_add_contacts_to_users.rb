class AddContactsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :contacts, :text, array: true
  end
end
