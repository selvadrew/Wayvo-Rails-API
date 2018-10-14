class AddDescriptionToFeedback < ActiveRecord::Migration[5.1]
  def change
    add_column :feedbacks, :description, :text
  end
end
