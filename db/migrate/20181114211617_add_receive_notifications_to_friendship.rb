class AddReceiveNotificationsToFriendship < ActiveRecord::Migration[5.1]
  def change
    add_column :friendships, :receive_notifications, :boolean, :default => true
  end
end
