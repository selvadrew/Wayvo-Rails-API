class Program < ApplicationRecord
  belongs_to :university
  has_many :group_connections
  has_many :program_group_members 
end
