class Api::V1::CustomGroupsController < ApplicationController
  before_action :authenticate_with_token!

  def create
  	proposed_username = params[:username].downcase
  	username_exists = CustomGroup.find_by(username: proposed_username)

    existing_username_school = Program.joins(:program_group_members).where(program_group_members: {user_id: username_exists.user_id} ).pluck(:university_id) if username_exists 
    creators_school = Program.joins(:program_group_members).where(program_group_members: {user_id: current_user.id} ).pluck(:university_id)

  	if username_exists && existing_username_school == creators_school
  		render json: { error: 1, is_success: false}, status: 404
  	else
        new_group = CustomGroup.new(
          user_id: current_user.id, 
          username: proposed_username,
          name: params[:name],
          description: params[:description]
        )
        group_leader = new_group.custom_group_member.build(user_id: current_user.id, status: true, notifications: true)

  		if new_group.save && group_leader.save
  			render json: { is_success: true }, status: :ok
  		else
  			render json: { error: 2, is_success: false}, status: 404
  		end
  	end
  end

end