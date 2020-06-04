class AddLastActiveHistoryToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_active_history, :jsonb, default: []
  end
end
