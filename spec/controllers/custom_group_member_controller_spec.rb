require 'rails_helper'

RSpec.describe Api::V1::CustomGroupMembersController, type: :controller do
	
	describe 'POST /search_groups' do 
		it 'returns a group' do
			post 'search_groups', params: { access_token: "qwwqwqwqrwrw", username: "ffc" }
			json = JSON.parse(response.body)

			expect(json["is_success"]).to eql(true)
		end
	end

end
