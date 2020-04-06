class CreateInvitations < ActiveRecord::Migration[5.1]
  def change
    create_table :invitations do |t|
      # t.references :user, foreign_key: true,
      t.integer :user_id
      # t.integer :received_invite_id
      t.integer :invitation_recipient_id

      t.timestamps
    end
  end
end
