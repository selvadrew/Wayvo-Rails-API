class CreatePlans < ActiveRecord::Migration[5.1]
  def change
    create_table :plans do |t|
      t.references :group, polymorphic: true
      t.references :user, foreign_key: true
      t.integer :activity
      t.integer :time
      t.integer :exploding_offer
      t.boolean :is_happening, default: false 

      t.timestamps
    end
  end
end
