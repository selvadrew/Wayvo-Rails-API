class CreateUniversities < ActiveRecord::Migration[5.1]
  def change
    create_table :universities do |t|
      t.string :university_name
      t.string :university_country

      t.timestamps
    end
  end
end
