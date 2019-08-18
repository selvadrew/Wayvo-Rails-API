class AddNotificationsToProgramGroupMembers < ActiveRecord::Migration[5.1]
  def change
    add_column :program_group_members, :notifications, :boolean, :default => true 
  end
end
