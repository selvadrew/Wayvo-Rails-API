class AddScheduledCallToInvitation < ActiveRecord::Migration[5.1]
  def change
    add_column :invitations, :scheduled_call, :timestamp
  end
end
