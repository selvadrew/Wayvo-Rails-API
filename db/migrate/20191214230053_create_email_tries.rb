class CreateEmailTries < ActiveRecord::Migration[5.1]
  def change
    create_table :email_tries do |t|
      t.string :email

      t.timestamps
    end
  end
end
