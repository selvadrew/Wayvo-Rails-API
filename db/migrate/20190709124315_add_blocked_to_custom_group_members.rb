class AddBlockedToCustomGroupMembers < ActiveRecord::Migration[5.1]
  def change
    add_column :custom_group_members, :blocked, :boolean, :default => false 
  end
end
