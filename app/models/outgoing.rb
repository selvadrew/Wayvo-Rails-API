class Outgoing < ApplicationRecord
  belongs_to :user
  has_one :acceptor
end
