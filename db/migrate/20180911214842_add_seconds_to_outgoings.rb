class AddSecondsToOutgoings < ActiveRecord::Migration[5.1]
  def change
    add_column :outgoings, :seconds, :integer
  end
end
