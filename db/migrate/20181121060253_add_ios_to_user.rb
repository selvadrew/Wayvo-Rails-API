class AddIosToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :iOS, :boolean, :default => false
  end
end
