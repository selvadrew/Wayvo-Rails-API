class CreateCalendars < ActiveRecord::Migration[5.1]
  def change
    create_table :calendars do |t|
      t.references :user, foreign_key: true
      t.jsonb :schedule

      t.timestamps
    end
  end
end
