class CreateOutgoings < ActiveRecord::Migration[5.1]
  def change
    create_table :outgoings do |t|
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
