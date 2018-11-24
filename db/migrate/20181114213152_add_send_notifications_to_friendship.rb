class AddSendNotificationsToFriendship < ActiveRecord::Migration[5.1]
  def change
    add_column :friendships, :send_notifications, :boolean, :default => true
  end
end
