class CreateAcceptors < ActiveRecord::Migration[5.1]
  def change
    create_table :acceptors do |t|
      t.references :outgoing, foreign_key: true
      t.integer :user_id

      t.timestamps
    end
  end
end
