class AddTimeZoneOffsetToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :time_zone_offset, :integer
  end
end
