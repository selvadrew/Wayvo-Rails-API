class AddContactNameToTextInvitations < ActiveRecord::Migration[5.1]
  def change
    add_column :text_invitations, :contact, :string
  end
end
