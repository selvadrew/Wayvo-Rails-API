class CreatePlanMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :plan_members do |t|
      t.references :plan, foreign_key: true
      t.references :user, foreign_key: true
      t.boolean :status, default: true 

      t.timestamps
    end
  end
end
