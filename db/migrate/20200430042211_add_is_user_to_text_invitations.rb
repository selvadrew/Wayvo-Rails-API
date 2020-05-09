class AddIsUserToTextInvitations < ActiveRecord::Migration[5.1]
  def change
    add_column :text_invitations, :is_user, :boolean, default: false 
  end
end
