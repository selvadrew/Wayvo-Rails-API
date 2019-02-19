class CreatePrograms < ActiveRecord::Migration[5.1]
  def change
    create_table :programs do |t|
      t.string :program_name
      t.references :university, foreign_key: true

      t.timestamps
    end
  end
end
