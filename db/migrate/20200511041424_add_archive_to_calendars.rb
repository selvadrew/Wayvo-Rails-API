class AddArchiveToCalendars < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :archive, :jsonb, default: {}
  end
end
