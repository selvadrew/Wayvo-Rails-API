class AddColumnsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :instagram, :string
    add_column :users, :snapchat, :string
    add_column :users, :twitter, :string
    add_column :users, :enrollment_date, :integer
    add_column :users, :verified, :boolean, :default => false 
  end
end
