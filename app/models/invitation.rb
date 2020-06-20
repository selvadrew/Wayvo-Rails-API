class Invitation < ApplicationRecord
  belongs_to :user
  belongs_to :invitation_recipient, :class_name => "User"
end
