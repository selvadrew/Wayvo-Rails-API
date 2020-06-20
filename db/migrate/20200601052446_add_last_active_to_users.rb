class AddLastActiveToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_active, :timestamp
  end
end
