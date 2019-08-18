class CreateCustomGroupMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_group_members do |t|
      t.references :custom_group, foreign_key: true
      t.integer :user_id
      t.boolean :status

      t.timestamps
    end
  end
end
