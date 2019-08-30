class AddSystemMessageToPlanMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :plan_messages, :system_message, :boolean, default: false 
  end
end
