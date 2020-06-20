class AddLastViewedToInvitations < ActiveRecord::Migration[5.1]
  def change
    add_column :invitations, :last_viewed, :timestamp
  end
end
