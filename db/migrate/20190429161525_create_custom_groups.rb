class CreateCustomGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_groups do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.string :username
      t.text :description

      t.timestamps
    end
  end
end
