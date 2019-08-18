class AddNotificationsToCustomGroupMembers < ActiveRecord::Migration[5.1]
  def change
    add_column :custom_group_members, :notifications, :boolean, :default => true 
  end
end
