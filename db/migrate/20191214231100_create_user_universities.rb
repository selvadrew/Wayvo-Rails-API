class CreateUserUniversities < ActiveRecord::Migration[5.1]
  def change

    create_join_table :users, :universities do |t|
      t.index :user_id
      t.index :university_id
    end

  end
end
