class CreateGroupConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :group_connections do |t|
      t.references :program, foreign_key: true
      t.integer :outgoing_user_id
      t.integer :acceptor_user_id

      t.timestamps
    end
  end
end
