class AddPhoneContactsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :phone_contacts, :jsonb
  end
end
