class CreateIncomingTexts < ActiveRecord::Migration[5.1]
  def change
    create_table :incoming_texts do |t|
      t.string :message_sid
      t.string :to
      t.string :from
      t.string :body
      t.string :sms_status
      t.integer :num_segments
      t.integer :num_media

      t.timestamps
    end
  end
end
