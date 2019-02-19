class CreateProgramGroupMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :program_group_members do |t|
      t.references :program, foreign_key: true
      t.integer :user_id

      t.timestamps
    end
  end
end
