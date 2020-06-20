class University < ApplicationRecord
	has_many :programs
	has_many :users
end
