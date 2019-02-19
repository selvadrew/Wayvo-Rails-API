class AddUniversityToUniversity < ActiveRecord::Migration[5.1]
  def change
    add_column :universities, :university, :boolean, :default => true
  end
end
