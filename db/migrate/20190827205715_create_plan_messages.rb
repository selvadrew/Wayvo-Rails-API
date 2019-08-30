class CreatePlanMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :plan_messages do |t|
      t.references :plan, foreign_key: true
      t.references :user, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
