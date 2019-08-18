class CustomGroupMember < ApplicationRecord
  belongs_to :custom_group
  belongs_to :user
end
