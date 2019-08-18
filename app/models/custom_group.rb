class CustomGroup < ApplicationRecord
  belongs_to :user
  has_many :custom_group_connection
  has_many :custom_group_member

  validates :username, format: { with: /\A[a-zA-Z0-9]{3,15}\z/ }, allow_nil: false

end
