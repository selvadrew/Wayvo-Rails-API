class AddUserReceiveNotificationsToFriendship < ActiveRecord::Migration[5.1]
  def change
    add_column :friendships, :user_receive_notifications, :boolean, :default => true
  end
end
