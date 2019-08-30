class Plan < ApplicationRecord
  # belongs_to :custom_group
  belongs_to :group, polymorphic: true
  belongs_to :user
  has_many :plan_members
  has_many :plan_messages
end
